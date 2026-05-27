# pawn_controller.gd
class_name PawnController
extends Node3D

signal step_reached(square_id: int)
signal movement_finished(square_id: int)

var _square_positions : Array[Vector3] = []
var current_square    : int     = 0
var is_moving         : bool    = false
var pawn_offset       : Vector3 = Vector3.ZERO
var pawn_index   : int   = 0
var _size_small  : float = 1.0
var _size_big    : float = 1.0

var _name_label : Label3D = null

func init(square_positions: Array[Vector3], small_size: float, big_size: float) -> void:
	_square_positions = square_positions
	_size_small = small_size
	_size_big = big_size

# Affiche le pseudo du joueur au-dessus du pion (Label3D billboard).
func set_player_name(player_name: String, color: Color = Color.WHITE) -> void:
	if _name_label == null:
		_name_label = Label3D.new()
		_name_label.billboard            = BaseMaterial3D.BILLBOARD_ENABLED
		_name_label.no_depth_test        = true     # toujours visible par-dessus la 3D
		_name_label.fixed_size           = true     # taille indépendante du zoom
		_name_label.pixel_size           = 0.0012   # taille à l'écran (ex 0.005 = énorme)
		_name_label.font_size            = 28
		_name_label.outline_size         = 4
		_name_label.modulate             = color
		_name_label.outline_modulate     = Color(0, 0, 0, 0.85)
		_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Décalage vertical par index → quand 4 pions sont sur la même case,
		# les labels s'empilent au lieu de se superposer.
		var y_offset : float = 0.9 + float(pawn_index) * 0.25
		_name_label.position = Vector3(0, y_offset, 0)
		add_child(_name_label)
	_name_label.text = player_name

func _get_side(sq: int) -> int:
	if sq < 10: return 0
	if sq < 20: return 1
	if sq < 30: return 2
	return 3

func _rotate_offset_for_side(offset: Vector3, side: int) -> Vector3:
	match side:
		0: return offset
		1: return Vector3(-offset.z, 0.0,  offset.x)
		2: return Vector3(-offset.x, 0.0, -offset.z)
		3: return Vector3( offset.z, 0.0, -offset.x)
	return offset

func teleport_to(square_id: int) -> void:
	if not _valid(square_id):
		return
	current_square = square_id
	var dynamic_offset = _get_dynamic_offset(square_id)
	global_position = _square_positions[square_id] + dynamic_offset

func move_to(from_sq: int, to_sq: int, step_duration: float = 0.28) -> void:
	if not _valid(from_sq) or not _valid(to_sq):
		push_error("PawnController.move_to : indices invalides (%d → %d)" % [from_sq, to_sq])
		return
	Global.pion_animation = 0
	if is_moving:
		await movement_finished

	is_moving = true
	teleport_to(from_sq)

	var steps : int = (to_sq - from_sq + 40) % 40
	SoundManager.play_step(steps)
	for i in range(1, steps + 1):
		var next_sq : int = (from_sq + i) % 40
		var dynamic_offset = _get_dynamic_offset(next_sq)
		var dest : Vector3 = _square_positions[next_sq] + dynamic_offset

		# Rotation vers la prochaine case (look_at pointe -Z vers la dest ; pas de PI flip)
		var dir := dest - global_position
		dir.y = 0.0
		if not dir.is_zero_approx():
			look_at(global_position + dir, Vector3.UP)

		# Animation rebond
		var mid_pos : Vector3 = global_position.lerp(dest, 0.5) + Vector3(0, 0.4, 0)

		var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(self, "global_position", mid_pos, step_duration * 0.5)
		tw.tween_property(self, "global_position", dest,    step_duration * 0.5)
		await tw.finished

		current_square = next_sq
		step_reached.emit(current_square)

	# Normalise rotation.y dans [-PI, PI] pour que le tween de retour prenne
	# toujours le chemin le plus court (évite le tour complet dans le mauvais sens).
	rotation.y = fmod(rotation.y, TAU)
	if rotation.y > PI:
		rotation.y -= TAU
	elif rotation.y < -PI:
		rotation.y += TAU

	# Retour à l'orientation neutre (face "avant") après le déplacement
	var return_tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return_tw.tween_property(self, "rotation:y", 0.0, 0.3)
	await return_tw.finished

	is_moving = false
	Global.pion_animation = 1
	movement_finished.emit(current_square)

func _valid(sq: int) -> bool:
	return sq >= 0 and sq < _square_positions.size()

func _get_dynamic_offset(sq: int) -> Vector3:
	var largeur : float = _size_small
	var hauteur : float = _size_big
	
	# Si c'est un coin (0, 10, 20, 30), on utilise le grand format pour la largeur aussi
	if sq % 10 == 0:
		largeur = _size_big

	var mult_x : float = 0.0
	var mult_z : float = 0.0
	
	match pawn_index:
		0:
			mult_x = 0.3
			mult_z = 0.3
		1:
			mult_x = 0.3
			mult_z = 0.7
		2:
			mult_x = 0.7
			mult_z = 0.3
		3:
			mult_x = 0.7
			mult_z = 0.7

	var local_offset = Vector3(largeur * mult_x, 0.0, hauteur * mult_z)
	return _rotate_offset_for_side(local_offset, _get_side(sq))
