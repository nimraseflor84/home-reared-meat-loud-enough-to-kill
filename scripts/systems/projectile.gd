extends Area2D

@export var speed: float = 400.0
@export var damage: float = 20.0
@export var direction: Vector2 = Vector2.RIGHT
@export var pierce_count: int = 0
@export var bounce_count: int = 0
@export var lifetime: float = 3.0
@export var size: float = 8.0

# 0=Manni(Drumstick), 1=Shouter(Soundbeam), 2=Dreads(Whip),
# 3=RiffSlicer(Pick), 4=Distortion(Blob), 5=Bassist(Basswave)
var proj_type: int = 0

var shooter = null
var _lifetime_timer: float = 0.0
var _pierced: int = 0
var _bounced: int = 0
var _hit_enemies: Array = []
var _anim_time: float = 0.0

func _ready() -> void:
	add_to_group("projectiles")
	# Collision setup
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = size
	col.shape = shape
	add_child(col)
	connect("area_entered", _on_area_entered)
	connect("body_entered", _on_body_entered)
	collision_layer = 4
	collision_mask = 2  # enemies layer

func _process(delta: float) -> void:
	_anim_time += delta
	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		queue_free()
		return

	global_position += direction * speed * delta
	queue_redraw()

	# -- Distance-based hit detection (Area2D body_entered unreliable mit direct movement) --
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	for i in range(enemies.size()):
		var enemy: Node2D = enemies[i] as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy in _hit_enemies:
			continue
		if global_position.distance_to(enemy.global_position) < size + 32.0:
			_hit_enemy(enemy)
			if not is_inside_tree():
				return  # Projektil wurde zerstoert

	# Bounce off screen edges (reverb_echo upgrade) or remove if out of viewport
	var vp = get_viewport_rect()
	if bounce_count > 0 and _bounced < bounce_count:
		var bounced := false
		if global_position.x <= 0:
			global_position.x = 1.0
			direction.x = abs(direction.x)
			bounced = true
		elif global_position.x >= vp.size.x:
			global_position.x = vp.size.x - 1.0
			direction.x = -abs(direction.x)
			bounced = true
		if global_position.y <= 0:
			global_position.y = 1.0
			direction.y = abs(direction.y)
			bounced = true
		elif global_position.y >= vp.size.y:
			global_position.y = vp.size.y - 1.0
			direction.y = -abs(direction.y)
			bounced = true
		if bounced:
			_bounced += 1
			_hit_enemies.clear()  # Nach Bounce wieder alle Gegner treffen koennen
	else:
		# Kein Bounce mehr oder kein Bounce-Upgrade: normal aus dem Screen entfernen
		if global_position.x < -50 or global_position.x > vp.size.x + 50 or \
		   global_position.y < -50 or global_position.y > vp.size.y + 50:
			queue_free()

func _draw() -> void:
	match proj_type:
		0: _draw_drumstick()
		1: _draw_soundbeam()
		2: _draw_whip()
		3: _draw_pick()
		4: _draw_distortion()
		5: _draw_basswave()
		6: _draw_merch_shirt()
		7: _draw_tape_roll()
		8: _draw_toxic_blob()
		_: _draw_drumstick()

# -- Manni: Two flying drumsticks ----------------------------------------------
func _draw_drumstick() -> void:
	draw_set_transform(Vector2.ZERO, direction.angle())
	var stick  = Color(0.50, 0.30, 0.12)
	var tip    = Color(0.90, 0.75, 0.42)
	var hi     = Color(0.70, 0.48, 0.20)
	# Upper stick
	draw_rect(Rect2(Vector2(-18, -5), Vector2(36, 4)), stick)
	draw_line(Vector2(-18, -3), Vector2(18, -3), hi, 1.0)
	draw_circle(Vector2(18, -3), 5, tip)
	# Lower stick
	draw_rect(Rect2(Vector2(-18,  2), Vector2(36, 4)), stick)
	draw_line(Vector2(-18,  4), Vector2(18,  4), hi, 1.0)
	draw_circle(Vector2(18,  4), 5, tip)
	draw_set_transform(Vector2.ZERO, 0.0)

# -- Shouter: Sound-wave arcs (beam pointing forward) -------------------------
func _draw_soundbeam() -> void:
	draw_set_transform(Vector2.ZERO, direction.angle())
	var pulse = sin(_anim_time * 12.0) * 0.2 + 0.8
	for i in range(3):
		var r = 7 + i * 9
		var alpha = (0.85 - i * 0.22) * pulse
		draw_arc(Vector2.ZERO, r, -PI * 0.40, PI * 0.40, 14,
				Color(0.95, 0.22, 0.05, alpha), 3.0 - i * 0.6)
	draw_circle(Vector2.ZERO, 5, Color(1.0, 0.70, 0.55, 0.95))
	draw_set_transform(Vector2.ZERO, 0.0)

# -- Dreads: Animated wavy whip ------------------------------------------------
func _draw_whip() -> void:
	draw_set_transform(Vector2.ZERO, direction.angle())
	var t = _anim_time * 9.0
	var pts = PackedVector2Array()
	for i in range(12):
		var x = -16.0 + float(i) / 11.0 * 32.0
		var y = sin(t + float(i) * 0.65) * 5.5
		pts.append(Vector2(x, y))
	if pts.size() > 1:
		draw_polyline(pts, Color(0.08, 0.82, 0.45, 0.92), 4.5)
	draw_circle(Vector2(16, 0), 5, Color(0.0, 1.0, 0.60, 0.9))
	draw_set_transform(Vector2.ZERO, 0.0)

# -- Riff Slicer: Spinning guitar pick ----------------------------------------
func _draw_pick() -> void:
	var angle = _anim_time * 9.0
	draw_set_transform(Vector2.ZERO, angle)
	var pts = PackedVector2Array([
		Vector2(0, -12),
		Vector2(10, 8),
		Vector2(-10, 8),
	])
	draw_colored_polygon(pts, Color(0.98, 0.48, 0.04))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]),
				  Color(1.0, 0.88, 0.25), 1.5)
	draw_circle(Vector2.ZERO, 3, Color(1.0, 0.95, 0.55, 0.85))
	draw_set_transform(Vector2.ZERO, 0.0)

# -- Distortion: Pulsing warped purple blob -----------------------------------
func _draw_distortion() -> void:
	var t  = _anim_time * 6.0
	var segs = 14
	var pts = PackedVector2Array()
	for i in range(segs + 1):
		var a = float(i) / segs * TAU
		var r = size + sin(t + a * 3.7) * 4.0 + sin(t * 1.6 + a * 2.1) * 2.5
		pts.append(Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, Color(0.62, 0.08, 0.92, 0.80))
	draw_circle(Vector2.ZERO, size * 0.45, Color(0.90, 0.55, 1.0, 1.0))

# -- Bassist: Dark blue core + expanding bass ripples -------------------------
func _draw_basswave() -> void:
	var pulse = sin(_anim_time * 6.0) * 0.15 + 0.85
	draw_circle(Vector2.ZERO, size * pulse, Color(0.06, 0.16, 0.78, 0.92))
	draw_circle(Vector2.ZERO, size * 0.42,  Color(0.32, 0.52, 1.0, 1.0))
	for i in range(2):
		var r = size + 10 + i * 13 + sin(_anim_time * 5.0 + i * 1.3) * 5
		draw_arc(Vector2.ZERO, r, 0, TAU, 18,
				Color(0.20, 0.42, 0.95, 0.42 - i * 0.14), 2.5)

# -- Pimmel: Rotierendes Merch-Shirt (gelb, mit Print) -------------------------
func _draw_merch_shirt() -> void:
	var angle = _anim_time * 7.0
	draw_set_transform(Vector2.ZERO, angle)
	var shirt = Color(0.97, 0.80, 0.10)
	# T-Shirt-Silhouette: Torso + zwei Aermel
	draw_rect(Rect2(-7, -8, 14, 16), shirt)
	draw_rect(Rect2(-12, -8, 5, 7), shirt)
	draw_rect(Rect2(7, -8, 5, 7), shirt)
	# Kragen
	draw_arc(Vector2(0, -8), 3.5, 0.0, PI, 8, Color(0.72, 0.55, 0.06), 1.5)
	# Band-Print (roter Punkt wie ein Logo)
	draw_circle(Vector2(0, 1), 3.0, Color(0.80, 0.12, 0.08))
	draw_set_transform(Vector2.ZERO, 0.0)

# -- Theo: Rotierende Gaffa-Tape-Rolle (grau, mit Loch) -------------------------
func _draw_tape_roll() -> void:
	var angle = _anim_time * 10.0
	draw_set_transform(Vector2.ZERO, angle)
	draw_circle(Vector2.ZERO, 9.0, Color(0.55, 0.55, 0.58))
	draw_circle(Vector2.ZERO, 4.0, Color(0.10, 0.10, 0.12))
	# Abstehendes Tape-Ende (flattert beim Rotieren)
	draw_line(Vector2(9, 0), Vector2(15, 3), Color(0.65, 0.65, 0.68), 3.0)
	# Glanzstreifen
	draw_arc(Vector2.ZERO, 7.0, 0.4, 1.4, 8, Color(0.78, 0.78, 0.80), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0)

# -- Toxo: Gruener, blubbernder Gift-Blob ---------------------------------------
func _draw_toxic_blob() -> void:
	var t = _anim_time * 6.0
	var segs = 14
	var pts = PackedVector2Array()
	for i in range(segs + 1):
		var a = float(i) / segs * TAU
		var r = size + sin(t + a * 3.7) * 4.0 + sin(t * 1.6 + a * 2.1) * 2.5
		pts.append(Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, Color(0.35, 0.78, 0.18, 0.85))
	draw_circle(Vector2.ZERO, size * 0.5, Color(0.75, 1.0, 0.30, 1.0))
	# Tropfen
	draw_circle(Vector2(size * 0.6, size * 0.5), 2.0, Color(0.55, 0.95, 0.20, 0.8))

func _hit_enemy(body: Node2D) -> void:
	# queue_free entfernt den Node erst am Frame-Ende: ohne diesen Guard traf
	# ein verbrauchtes Projektil im selben Frame weitere Gegner (Audit Run #11)
	if is_queued_for_deletion():
		return
	if body == null or not is_instance_valid(body) or body in _hit_enemies:
		return
	_hit_enemies.append(body)
	# Duck-type check: enemies have 'is_alive' property; bare nodes do not
	if body.get("is_alive") != null:
		body.take_damage(damage, shooter)
	AudioManager.play_hit_sfx()

	# Slow zone upgrade
	if is_instance_valid(shooter) and shooter.has_upgrade("wall_of_sound"):
		if body.get("is_alive") != null:
			body.apply_slow(0.5, 2.0)

	if _pierced < pierce_count:
		_pierced += 1
	else:
		queue_free()

func _on_area_entered(_area: Area2D) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	# Fallback: physics-based detection (ergaenzt distance-check in _process)
	if body.is_in_group("enemies"):
		_hit_enemy(body)
