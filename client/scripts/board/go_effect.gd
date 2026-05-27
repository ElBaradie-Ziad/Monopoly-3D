# go_effect.gd
# Animation quand le joueur passe par GO :
#   1. Flash lumineux doré autour de la case GO
#   2. Particules qui explosent vers le haut
#   3. Texte flottant "+200€" qui monte et disparaît
#
# Usage depuis sandbox_board.gd :
#   _go_effect.play(go_pos)
#   await _go_effect.finished

extends Node3D

signal finished

@export var flash_duration  : float = 1.5
@export var flash_intensity : float = 12.0
@export var text_rise_speed : float = 2.0


func _process(delta: float) -> void:
	pass


# ══════════════════════════════ API publique ══════════════════════════════════

func play(go_pos: Vector3) -> void:
	# Lancer tout en parallèle
	_flash_gold(go_pos)
	_spawn_particles(go_pos)
	_spawn_floating_text(go_pos)
	
	await get_tree().create_timer(flash_duration + 0.5).timeout
	
	finished.emit()


# ══════════════════════════ Fonctions privées ══════════════════════════════════

func _flash_gold(pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.light_color     = Color(1.0, 0.85, 0.0)  # doré
	light.light_energy    = flash_intensity
	light.omni_range      = 6.0
	light.global_position = pos + Vector3(0, 1.0, 0)
	add_child(light)

	# Pulse : montée rapide puis descente douce
	var tw := create_tween()
	tw.tween_property(light, "light_energy", flash_intensity * 1.5, 0.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(light, "light_energy", 0.0, flash_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	light.queue_free()

func _spawn_particles(pos: Vector3) -> void:
	# Simulation de particules avec des petits cubes dorés qui montent
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(12):
		var particle := MeshInstance3D.new()
		var mesh     := BoxMesh.new()
		mesh.size            = Vector3(0.06, 0.06, 0.06)
		particle.mesh        = mesh
		var mat              := StandardMaterial3D.new()
		mat.albedo_color     = Color(1.0, 0.85, 0.0)
		mat.emission_enabled = true
		mat.emission         = Color(1.0, 0.85, 0.0) * 0.8
		particle.material_override = mat

		# Position de départ aléatoire autour de GO
		var offset := Vector3(
			rng.randf_range(-0.4, 0.4),
			0.1,
			rng.randf_range(-0.4, 0.4)
		)
		particle.global_position = pos + offset
		add_child(particle)

		# Animation : monter + fade out
		var height := rng.randf_range(0.8, 2.0)
		var dur    := rng.randf_range(0.6, 1.2)
		var delay  := rng.randf_range(0.0, 0.3)

		var tw := create_tween().set_parallel(true)
		tw.tween_property(particle, "global_position",
			pos + offset + Vector3(0, height, 0), dur)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(particle, "scale",
			Vector3(0.01, 0.01, 0.01), dur * 0.8)\
			.set_delay(delay + dur * 0.2)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		# Cleanup
		var cleanup_timer := dur + delay + 0.1
		get_tree().create_timer(cleanup_timer).timeout.connect(
			func(): if is_instance_valid(particle): particle.queue_free()
		)

func _spawn_floating_text(pos: Vector3) -> void:
	SoundManager.play_depart()
	var label := Label3D.new()
	label.text                 = "+200M"
	if Global.classe3.has(Global.current_client_id):
		label.text= "+275M"
	label.font_size            = 72
	label.modulate             = Color(1.0, 0.85, 0.0)
	label.outline_size         = 8
	label.outline_modulate     = Color(0.6, 0.4, 0.0)
	label.billboard            = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test        = true
	label.pixel_size           = 0.012
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.global_position      = pos + Vector3(0, 1.0, 0)
	add_child(label)

	# Animation : monter + disparaître
	var tw := create_tween().set_parallel(true)
	tw.tween_property(label, "global_position",
		pos + Vector3(0, 3.0, 0), 1.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate",
		Color(1.0, 0.85, 0.0, 0.0), 1.5)\
		.set_delay(0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(label):
		label.queue_free()
