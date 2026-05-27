# HouseSpawnEffect.gd
extends Node3D

@onready var house_mesh: MeshInstance3D = $HouseMesh
@onready var particles: GPUParticles3D = $GPUParticles3D

@export var bounce_height  : float   = 0.6
@export var squash_strength: float   = 0.7
@export var duration       : float   = 0.9
@export var final_scale    : Vector3 = Vector3(0.1, 0.1, 0.1)  # ← modifiable depuis building_manager

func _ready() -> void:
	house_mesh.scale    = Vector3(0.01, 0.01, 0.01)
	house_mesh.position = Vector3.ZERO  # ← reset X, Y ET Z
	spawn_with_bounce()

func spawn_with_bounce() -> void:
	# Calcul des scales intermédiaires proportionnels au final_scale
	var fs      := final_scale
	var explode := Vector3(fs.x * 1.8, fs.y * 0.6, fs.z * 1.8)
	var squash  := Vector3(fs.x * 0.7 * squash_strength, fs.y * 1.4, fs.z * 0.7 * squash_strength)
	var overshoot := Vector3(fs.x * 1.15, fs.y * 0.85, fs.z * 1.15)

	var tween = create_tween()
	SoundManager.house_build()
	# 1. Apparition explosive
	tween.tween_property(house_mesh, "scale", explode, 0.35)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(house_mesh, "position:y", bounce_height, 0.32)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Squash + descente
	tween.tween_property(house_mesh, "scale", squash, 0.22)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.tween_property(house_mesh, "position:y", 0.0, 0.25)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# 3. Rebond final → stabilisation à final_scale
	tween.tween_property(house_mesh, "scale", overshoot, 0.15)\
		.set_trans(Tween.TRANS_QUAD)

	tween.tween_property(house_mesh, "scale", fs, 0.18)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Particules
	await get_tree().create_timer(0.52).timeout
	if has_node("GPUParticles3D"):
		$GPUParticles3D.emitting = true
