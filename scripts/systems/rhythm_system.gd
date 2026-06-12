extends Node

# BPM und Beat-Interval werden aus AudioManager synchronisiert (kein hardcodierter Wert)
const DEFAULT_BPM       = 120.0
const RHYTHM_WINDOW     = 0.15   # ±0.15s Treffertoleranz
const MAX_COMBO         = 8      # Standard-Cap für x4-Multiplikator

var _bpm: float          = DEFAULT_BPM
var _beat_interval: float = 60.0 / DEFAULT_BPM
var _beat_timer: float   = 0.0
var _combo: int          = 0
var _current_combo_multiplier: float = 1.0
var _last_attack_beat_time: float = -999.0
var _extra_window: float = 0.0   # von Upgrades
var _extra_combo_cap: int = 0    # von Upgrades

signal beat_occurred()
signal rhythm_hit(multiplier)
signal rhythm_miss()
signal combo_changed(combo, multiplier)

func _ready() -> void:
	# BPM-Änderungen von AudioManager empfangen
	if is_instance_valid(AudioManager):
		AudioManager.song_changed.connect(_on_song_changed)
		# Aktuelles BPM sofort übernehmen falls Musik schon läuft
		_set_bpm(AudioManager.get_current_bpm())

func _on_song_changed(_title: String, bpm: float) -> void:
	_set_bpm(bpm)

func _set_bpm(bpm: float) -> void:
	_bpm = max(60.0, bpm)  # Minimum 60 BPM als Schutz gegen Division durch 0
	_beat_interval = 60.0 / _bpm
	# Beat-Timer anteilig beibehalten (kein harter Jump → fühlt sich sauberer an)
	_beat_timer = _beat_timer * (_beat_interval / max(0.001, _beat_interval))

func _process(delta: float) -> void:
	_beat_timer += delta
	if _beat_timer >= _beat_interval:
		_beat_timer -= _beat_interval
		emit_signal("beat_occurred")

func get_beat_progress() -> float:
	return _beat_timer / _beat_interval

func get_time_to_beat() -> float:
	var half = _beat_interval / 2.0
	if _beat_timer < half:
		return _beat_timer
	else:
		return _beat_timer - _beat_interval

func register_attack() -> float:
	# Returns rhythm multiplier (1.0 = no bonus, 1.25+ = rhythm hit)
	var time_to_beat = abs(get_time_to_beat())
	var window = RHYTHM_WINDOW + _extra_window

	if time_to_beat <= window:
		_combo += 1
		var max_combo = MAX_COMBO + _extra_combo_cap
		_current_combo_multiplier = 1.0 + 0.25 * min(_combo / 2, max_combo / 2)
		emit_signal("rhythm_hit", _current_combo_multiplier)
		emit_signal("combo_changed", _combo, _current_combo_multiplier)
		AudioManager.play_rhythm_hit_sfx()
		return _current_combo_multiplier
	else:
		if _combo > 0:
			emit_signal("rhythm_miss")
		_combo = 0
		_current_combo_multiplier = 1.0
		emit_signal("combo_changed", _combo, _current_combo_multiplier)
		return 1.0

func get_combo() -> int:
	return _combo

func get_multiplier() -> float:
	return _current_combo_multiplier

func apply_upgrade(upgrade: Dictionary) -> void:
	var effect = upgrade.get("effect", {})
	if effect.has("rhythm_window_bonus"):
		_extra_window += effect["rhythm_window_bonus"]
	if effect.has("combo_cap_bonus"):
		_extra_combo_cap += effect["combo_cap_bonus"]

func reset() -> void:
	_beat_timer = 0.0
	_combo = 0
	_current_combo_multiplier = 1.0
