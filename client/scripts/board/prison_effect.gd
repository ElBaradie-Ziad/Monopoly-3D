# prison_effect.gd
extends Node3D

signal finished

const JAIL_SCENE : PackedScene = preload("res://design_raw/textures_sources/Jail.tscn")

@export var siren_duration   : float   = 3.0
@export var siren_flash_rate : float   = 0.12
@export var cage_fall_height : float   = 4.0
@export var cage_fall_dur    : float   = 0.7
@export var jail_scale       : float   = 0.033
@export var jail_offset      : Vector3 = Vector3(-0.550, 0.0, 0.396)
@export var jail_cage_offset : Vector3 = Vector3(-1.5, 0.0, 1.5)

# Intensité d'assombrissement du plateau (0 = noir total, 1 = normal)
@export var dim_energy       : float   = 0.2
@export var dim_duration     : float   = 0.5

const PRISONER_OFFSETS : Array = [
	Vector3( 0.3, 0,  0.3),
	Vector3(-0.3, 0,  0.3),
	Vector3( 0.3, 0, -0.3),
	Vector3(-0.3, 0, -0.3),
]

var _cage_node      : Node3D           = null
var _light_blue     : OmniLight3D      = null
var _light_red      : OmniLight3D      = null
var _dir_light      : DirectionalLight3D = null
var _camera         = null
var _siren_timer    : float = 0.0
var _siren_active   : bool  = false
var _flash_timer    : float = 0.0
var _blue_on        : bool  = true
var _prisoners      : Array = []
var _original_energy: float = 1.2


func init(camera, dir_light: DirectionalLight3D) -> void:
	_camera    = camera
	_dir_light = dir_light
	if _dir_light:
		_original_energy = _dir_light.light_energy


func _process(delta: float) -> void:
	if not _siren_active:
		return
	_siren_timer -= delta
	_flash_timer  -= delta
	if _flash_timer <= 0.0:
		_flash_timer = siren_flash_rate
		_blue_on = not _blue_on
		if _light_blue and _light_red:
			_light_blue.visible = _blue_on
			_light_red.visible  = not _blue_on
	if _siren_timer <= 0.0:
		_stop_siren()


func play(pawn_node: Node3D, prison_pos: Vector3) -> void:
	_start_siren(pawn_node.global_position)

	await get_tree().create_timer(siren_duration * 0.6).timeout

	_prisoners.append(pawn_node)
	var prisoner_index : int = _prisoners.size() - 1
	var offset : Vector3 = PRISONER_OFFSETS[prisoner_index % PRISONER_OFFSETS.size()]
	pawn_node.global_position = prison_pos + jail_offset + offset
	pawn_node.current_square  = 10

	if _light_blue and _light_red:
		_light_blue.global_position = prison_pos + Vector3(-0.5, 1.5, 0)
		_light_red.global_position  = prison_pos + Vector3( 0.5, 1.5, 0)

	await get_tree().create_timer(siren_duration * 0.4).timeout

	if _cage_node == null:
		SoundManager.play_prison()
		_spawn_cage(prison_pos)

	# Attendre que la cage touche le sol
	await get_tree().create_timer(cage_fall_dur).timeout

	# ── Impact : screen shake + assombrissement ──
	if _camera:
		_camera.shake(0.5, 0.3)
	_dim_lights(true)

	await get_tree().create_timer(0.3).timeout
	await get_tree().create_timer(3.0).timeout
	remove_cage()

	finished.emit()

func release_prisoner(pawn_node: Node3D) -> void:
	_prisoners.erase(pawn_node)

func remove_cage() -> void:
	# Remettre les lumières normales
	_dim_lights(false)

	if _cage_node and is_instance_valid(_cage_node):
		var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_property(_cage_node, "scale", Vector3(0.01, 0.01, 0.01), 0.4)
		await tw.finished
		_cage_node.queue_free()
		_cage_node = null
	_prisoners.clear()


func _dim_lights(dim: bool) -> void:
	if _dir_light == null:
		return
	var target_energy := dim_energy if dim else _original_energy
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(_dir_light, "light_energy", target_energy, dim_duration)

func _start_siren(pos: Vector3) -> void:
	_light_blue = OmniLight3D.new()
	_light_blue.light_color = Color(0.1, 0.3, 1.0)
	_light_blue.light_energy = 8.0
	_light_blue.omni_range = 5.0
	_light_blue.global_position = pos + Vector3(-0.5, 1.5, 0)
	add_child(_light_blue)

	_light_red = OmniLight3D.new()
	_light_red.light_color = Color(1.0, 0.1, 0.1)
	_light_red.light_energy = 8.0
	_light_red.omni_range = 5.0
	_light_red.global_position = pos + Vector3(0.5, 1.5, 0)
	_light_red.visible = false
	add_child(_light_red)

	# === Son géré par SoundManager ===
	SoundManager.play_siren()

	_siren_timer = siren_duration
	_flash_timer = siren_flash_rate
	_siren_active = true
	_blue_on = true
	
	
func _stop_siren() -> void:
	_siren_active = false

	if _light_blue:
		_light_blue.queue_free()
		_light_blue = null
	if _light_red:
		_light_red.queue_free()
		_light_red = null

	# Plus de gestion manuelle du son ici
	# SoundManager s’occupe de la sirène

func _spawn_cage(pos: Vector3) -> void:
	_cage_node = JAIL_SCENE.instantiate()
	_cage_node.scale            = Vector3(jail_scale, jail_scale, jail_scale)
	_cage_node.rotation_degrees = Vector3(-90, 0, 0)
	add_child(_cage_node)

	await get_tree().process_frame

	var target_pos : Vector3 = pos + jail_cage_offset
	var start_pos  : Vector3 = Vector3(target_pos.x, target_pos.y + cage_fall_height, target_pos.z)
	_cage_node.global_position = start_pos

	var tw := create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_cage_node, "global_position", target_pos, cage_fall_dur)
