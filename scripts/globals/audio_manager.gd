extends Node

# ── Musik ──────────────────────────────────────────────────────────────────
const SONGS = [
	{"title": "Dumb Boys",            "path": "res://assets/music/dumb_boys.mp3"},
	{"title": "Medusa",               "path": "res://assets/music/medusa.mp3"},
	{"title": "Drink Fight Die",      "path": "res://assets/music/drink_fight_die.mp3"},
	{"title": "Bolognese Bloodbath",  "path": "res://assets/music/bolognese_bloodbath.mp3"},
	{"title": "Empire of Scum",       "path": "res://assets/music/empire_of_scum.mp3"},
	{"title": "Evisceration Parade",  "path": "res://assets/music/evisceration_parade.mp3"},
]

var music_player: AudioStreamPlayer
var siren_player: AudioStreamPlayer
var _sfx_pool: Array = []
const SFX_POOL_SIZE = 6

var _playlist: Array = []
var _current_index: int = 0
var _music_volume: float = 0.8
var _music_enabled: bool = true
var _proj_sfx_enabled: bool = true
var _current_song_title: String = ""

# BPM-Beat-System (120 BPM)
const BPM = 120.0
const BEAT_INTERVAL = 60.0 / BPM
var _beat_timer: float = 0.0
var _beat_active: bool = false

signal beat_occurred()
signal song_changed(title: String)

# Precomputed SFX
var _sfx_hit: AudioStreamWAV = null
var _sfx_rhythm: AudioStreamWAV = null
var _sfx_ultimate: AudioStreamWAV = null
var _sfx_wave_complete: AudioStreamWAV = null
var _sfx_death: AudioStreamWAV = null
var _sfx_siren: AudioStreamWAV = null
var _sfx_siren_mp3: AudioStreamMP3 = null
var _sfx_projectiles: Array = []
var _sfx_player_death: AudioStreamWAV = null
var _sfx_boss_death: AudioStreamWAV = null
var _sfx_whistle: AudioStreamWAV = null
var _sfx_squeal: AudioStreamWAV  = null
var _sfx_evil_laugh: AudioStreamMP3 = null
var _elevator_player: AudioStreamPlayer

# ── Setup ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)
	music_player.finished.connect(_on_song_finished)

	siren_player = AudioStreamPlayer.new()
	siren_player.bus = "SFX"
	siren_player.volume_db = -8.0
	siren_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(siren_player)

	for i in range(SFX_POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		p.volume_db = 2.0
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_sfx_pool.append(p)

	_elevator_player = AudioStreamPlayer.new()
	_elevator_player.bus = "Music"
	_elevator_player.volume_db = -4.0
	_elevator_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_elevator_player)

	_music_volume = 0.8
	_music_enabled = true
	_precompute_sfx()
	_rebuild_playlist()
	call_deferred("_load_settings")

func _load_settings() -> void:
	if not is_instance_valid(SaveManager):
		return
	var vol = SaveManager.get_setting("music_volume")
	if vol != null:
		_music_volume = clamp(float(vol), 0.0, 1.0)
	var enabled = SaveManager.get_setting("music_enabled")
	if enabled != null:
		_music_enabled = bool(enabled)
	var proj_sfx = SaveManager.get_setting("proj_sfx_enabled")
	if proj_sfx != null:
		_proj_sfx_enabled = bool(proj_sfx)
	if is_instance_valid(music_player):
		if not _music_enabled:
			music_player.volume_db = -80.0
		else:
			music_player.volume_db = _volume_to_db(_music_volume)

func _process(delta: float) -> void:
	if _beat_active:
		_beat_timer += delta
		if _beat_timer >= BEAT_INTERVAL:
			_beat_timer -= BEAT_INTERVAL
			emit_signal("beat_occurred")

# ── Musik-Steuerung ─────────────────────────────────────────────────────────
func start_music() -> void:
	if not _music_enabled:
		return
	if not music_player.playing:
		_play_current()
	_beat_active = true
	_beat_timer = 0.0

func stop_music() -> void:
	music_player.stop()
	_beat_active = false

func pause_music() -> void:
	music_player.stream_paused = true
	_beat_active = false

func resume_music() -> void:
	if _music_enabled:
		music_player.stream_paused = false
		_beat_active = true

func next_song() -> void:
	_current_index = (_current_index + 1) % _playlist.size()
	_play_current()

func _load_mp3(path: String) -> AudioStreamMP3:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	var bytes = file.get_buffer(file.get_length())
	file.close()
	if bytes.size() == 0:
		return null
	var stream = AudioStreamMP3.new()
	stream.data = bytes
	return stream

func _play_current() -> void:
	if _playlist.is_empty():
		return
	var tries = 0
	while tries < _playlist.size():
		var song = _playlist[_current_index]
		var stream = _load_mp3(song["path"])
		if stream:
			music_player.stream = stream
			music_player.volume_db = _volume_to_db(_music_volume)
			if not _music_enabled:
				music_player.volume_db = -80.0
			music_player.play()
			_current_song_title = song["title"]
			emit_signal("song_changed", _current_song_title)
			return
		tries += 1
		_current_index = (_current_index + 1) % _playlist.size()
	_current_song_title = ""

func _on_song_finished() -> void:
	_current_index = (_current_index + 1) % _playlist.size()
	_play_current()

func _rebuild_playlist() -> void:
	_playlist = SONGS.duplicate()
	_playlist.shuffle()
	_current_index = 0

func _volume_to_db(vol: float) -> float:
	if vol <= 0.0:
		return -80.0
	return 20.0 * log(vol) / log(10.0)

# ── Lautstärke ──────────────────────────────────────────────────────────────
func set_music_volume(vol: float) -> void:
	_music_volume = clamp(vol, 0.0, 1.0)
	music_player.volume_db = _volume_to_db(_music_volume)
	if is_instance_valid(SaveManager):
		SaveManager.set_setting("music_volume", _music_volume)

func get_music_volume() -> float:
	return _music_volume

func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	if is_instance_valid(SaveManager):
		SaveManager.set_setting("music_enabled", enabled)
	if enabled:
		music_player.volume_db = _volume_to_db(_music_volume)
		if not music_player.playing:
			_play_current()
	else:
		music_player.volume_db = -80.0

func get_music_enabled() -> bool:
	return _music_enabled

func get_current_song_title() -> String:
	return _current_song_title

# ── Beat ────────────────────────────────────────────────────────────────────
func get_beat_progress() -> float:
	return _beat_timer / BEAT_INTERVAL

# ── SFX: Prozedurales WAV-Generator ────────────────────────────────────────
# Generiert einen Sinuston mit Pitch-Glide und Attack-Decay-Hüllkurve
func _gen_wav(freq_start: float, freq_end: float, duration: float, vol: float = 0.45) -> AudioStreamWAV:
	var rate = 22050
	var n = int(rate * duration)
	if n <= 0:
		return null
	var data = PackedByteArray()
	data.resize(n * 2)
	var phase = 0.0
	for i in range(n):
		var t = float(i) / float(n)
		var freq = lerp(freq_start, freq_end, t)
		phase = fmod(phase + freq / float(rate), 1.0)
		var s = sin(phase * TAU)
		# Envelope: kurzer Attack, exponentieller Decay
		var env: float
		if t < 0.04:
			env = t / 0.04
		else:
			env = pow(1.0 - (t - 0.04) / 0.96, 0.65)
		var sample = clamp(int(s * env * vol * 32767.0), -32768, 32767)
		data[i * 2]     = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav

# Mehrschichtiger WAV-Generator (mischt mehrere Sinustöne)
# layers: Array von {freq_start, freq_end, vol, decay(optional)}
func _gen_wav_layered(layers: Array, duration: float) -> AudioStreamWAV:
	var rate = 22050
	var n = int(rate * duration)
	if n <= 0:
		return null
	var data = PackedByteArray()
	data.resize(n * 2)
	var phases: Array = []
	for _l in layers:
		phases.append(0.0)
	for i in range(n):
		var t = float(i) / float(n)
		var mix = 0.0
		for j in range(layers.size()):
			var layer = layers[j]
			var freq = lerp(float(layer["freq_start"]), float(layer["freq_end"]), t)
			phases[j] = fmod(phases[j] + freq / float(rate), 1.0)
			var env: float
			if t < 0.04:
				env = t / 0.04
			else:
				var decay = layer.get("decay", 0.65)
				env = pow(1.0 - (t - 0.04) / 0.96, decay)
			mix += sin(phases[j] * TAU) * env * float(layer["vol"])
		var sample = clamp(int(mix * 32767.0), -32768, 32767)
		data[i * 2]     = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav

# Luftalarm – mechanische Rotationssirene (WWII-Stil)
# Realistisch: langsames Anlaufen, ungleichmäßige Harmonische, mechanisches Brummen
func _gen_siren() -> AudioStreamWAV:
	var rate = 22050
	var duration = 7.0    # ~2.5 volle Wail-Zyklen
	var n = int(rate * duration)
	var data = PackedByteArray()
	data.resize(n * 2)
	var ph1 = 0.0   # Grundton (Rotor-Hauptton)
	var ph2 = 0.0   # 2. Harmonische
	var ph3 = 0.0   # Subharmonic (Motorbrummen)
	var ph4 = 0.0   # 3. Harmonische (leicht verstimmt → Klirreffekt)
	var ph5 = 0.0   # 5. Harmonische (Metallresonanz)
	for i in range(n):
		var secs = float(i) / float(rate)
		# LFO: 0.32 Hz → Periode ≈ 3.1 s (träger, realistischer)
		# Mit leichter Asymmetrie: Anstieg langsamer als Abfall
		var lfo_raw = sin(secs * TAU * 0.32 - PI * 0.5)
		# Asymmetrische Kurve: langsamer Aufstieg, schnellerer Abfall
		var lfo = pow(lfo_raw * 0.5 + 0.5, 0.75)
		# Anlauf-Effekt: erste 1.5s baut Frequenz auf (wie Rotor der hochläuft)
		var spin_up = min(1.0, secs / 1.5)
		# Frequenzbereich: 180 Hz (tief, Anlauf) → 760 Hz (Hochpunkt)
		var freq = (180.0 + lfo * 580.0) * spin_up + 80.0 * (1.0 - spin_up)
		# Leichte Frequenzschwankung (mechanische Ungenauigkeit)
		var wobble = sin(secs * TAU * 7.3) * 2.0 + sin(secs * TAU * 11.7) * 1.0
		freq += wobble * spin_up
		ph1 = fmod(ph1 + freq          / float(rate), 1.0)
		ph2 = fmod(ph2 + freq * 2.0    / float(rate), 1.0)
		ph3 = fmod(ph3 + freq * 0.5    / float(rate), 1.0)
		ph4 = fmod(ph4 + freq * 3.03   / float(rate), 1.0)   # leicht verstimmt
		ph5 = fmod(ph5 + freq * 4.98   / float(rate), 1.0)   # leicht verstimmt
		# Wellenform-Mix: Grundton dominant, Subharmonic gibt Tiefe und Druck
		# Leichtes Clipping simuliert mechanische Verzerrung
		var s = sin(ph1 * TAU) * 0.48  \
		      + sin(ph2 * TAU) * 0.22  \
		      + sin(ph3 * TAU) * 0.18  \
		      + sin(ph4 * TAU) * 0.08  \
		      + sin(ph5 * TAU) * 0.04
		# Soft-Clipping für mechanischen Charakter
		s = s / (1.0 + abs(s) * 0.4)
		# Hüllkurve: 0.8s Fade-in, 0.6s Fade-out
		var env = min(1.0, secs / 0.8) * min(1.0, (duration - secs) / 0.6)
		# Lautstärke folgt dem LFO (lauter bei hoher Frequenz, wie echte Sirene)
		var vol_mod = 0.70 + lfo * 0.30
		var sample = clamp(int(s * env * vol_mod * 0.60 * 32767.0), -32768, 32767)
		data[i * 2]     = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav

func _precompute_sfx() -> void:
	_sfx_hit          = _gen_wav(900.0,  200.0,  0.07, 0.45)
	_sfx_rhythm       = _gen_wav(523.0,  523.0,  0.14, 0.42)
	_sfx_ultimate     = _gen_wav(80.0,   35.0,   0.55, 0.72)
	_sfx_wave_complete = _gen_wav(440.0, 880.0,  0.35, 0.52)
	_sfx_death        = _gen_wav(550.0,  80.0,   0.14, 0.38)
	_sfx_siren        = _gen_siren()
	_sfx_siren_mp3    = _load_mp3("res://assets/sounds/boss_siren.mp3")
	# Spieler-Tod: dramatischer Gitarren-Power-Chord-Absturz (3 Schichten)
	_sfx_player_death = _gen_wav_layered([
		{"freq_start": 880.0, "freq_end":  90.0, "vol": 0.22, "decay": 0.50},
		{"freq_start": 440.0, "freq_end":  45.0, "vol": 0.28, "decay": 0.44},
		{"freq_start": 220.0, "freq_end":  22.0, "vol": 0.25, "decay": 0.38},
	], 0.90)
	# Boss-Tod: epische Explosion mit tiefem Bass (4 Schichten, 1.5s)
	_sfx_boss_death = _gen_wav_layered([
		{"freq_start": 280.0,  "freq_end":  22.0, "vol": 0.28, "decay": 0.35},
		{"freq_start": 140.0,  "freq_end":  14.0, "vol": 0.24, "decay": 0.30},
		{"freq_start": 700.0,  "freq_end": 100.0, "vol": 0.16, "decay": 0.50},
		{"freq_start": 1800.0, "freq_end": 300.0, "vol": 0.10, "decay": 0.65},
	], 1.50)
	# Bauernpfiff: kurzer aufsteigender Pfiff (1800→2800 Hz, 0.28s)
	_sfx_whistle = _gen_wav(1800.0, 2800.0, 0.28, 0.32)
	# Schweine-Quieken: schriller Abfall (2800→600 Hz, 0.38s)
	_sfx_squeal  = _gen_wav(2800.0, 600.0, 0.38, 0.40)
	# Gruseliges dunkles Männerlachen: echte MP3-Datei
	_sfx_evil_laugh = _load_mp3("res://assets/sounds/evil_laugh.mp3")
	_sfx_projectiles = [
		_gen_wav(1200.0, 700.0,  0.06, 0.30),
		_gen_wav(2000.0, 1500.0, 0.10, 0.25),
		_gen_wav(900.0,  250.0,  0.08, 0.30),
		_gen_wav(1900.0, 2400.0, 0.05, 0.28),
		_gen_wav(600.0,  150.0,  0.16, 0.27),
		_gen_wav(180.0,  60.0,   0.14, 0.42),
	]

# ── Pause-Musik (echte MP3-Datei) ────────────────────────────────────────────
func play_elevator_music() -> void:
	if not is_instance_valid(_elevator_player):
		return
	var stream = _load_mp3("res://assets/music/pause_music.mp3")
	if not stream:
		return
	stream.loop = true
	_elevator_player.stream = stream
	_elevator_player.play()

func stop_elevator_music() -> void:
	if is_instance_valid(_elevator_player):
		_elevator_player.stop()

func _play_sfx(stream: AudioStreamWAV) -> void:
	if not stream:
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	# Fallback: ältesten ersetzen
	_sfx_pool[0].stream = stream
	_sfx_pool[0].play()

# ── SFX-Aufrufe (von Spiellogik verwendet) ──────────────────────────────────
func play_hit_sfx() -> void:
	_play_sfx(_sfx_hit)

func play_rhythm_hit_sfx() -> void:
	_play_sfx(_sfx_rhythm)

func play_ultimate_sfx() -> void:
	_play_sfx(_sfx_ultimate)

func play_wave_complete_sfx() -> void:
	_play_sfx(_sfx_wave_complete)

func play_enemy_death_sfx() -> void:
	_play_sfx(_sfx_death)

func play_player_death_sfx() -> void:
	_play_sfx(_sfx_player_death)

func play_boss_death_sfx() -> void:
	_play_sfx(_sfx_boss_death)

func play_whistle_sfx() -> void:
	_play_sfx(_sfx_whistle)

func play_squeal_sfx() -> void:
	_play_sfx(_sfx_squeal)

func play_evil_laugh() -> void:
	if not _sfx_evil_laugh:
		return
	# Separater Player damit das Lachen nicht vom SFX-Pool abgeschnitten wird
	var p = AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = _sfx_evil_laugh
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func play_boss_siren_sfx() -> void:
	if _sfx_siren_mp3:
		siren_player.stream = _sfx_siren_mp3
	elif _sfx_siren:
		siren_player.stream = _sfx_siren
	else:
		return
	siren_player.play()

# variety: 0=Manni 1=Shouter 2=Dreads 3=RiffSlicer 4=Distortion 5=Bassist
func play_projectile_sfx(variety: int = 0) -> void:
	if not _proj_sfx_enabled or _sfx_projectiles.is_empty():
		return
	var idx = clamp(variety, 0, _sfx_projectiles.size() - 1)
	_play_sfx(_sfx_projectiles[idx])

func set_proj_sfx_enabled(enabled: bool) -> void:
	_proj_sfx_enabled = enabled
	if is_instance_valid(SaveManager):
		SaveManager.set_setting("proj_sfx_enabled", enabled)

func get_proj_sfx_enabled() -> bool:
	return _proj_sfx_enabled
