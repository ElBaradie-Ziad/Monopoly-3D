extends Camera3D

@export var global_height : float = 14.0
@export var follow_height : float = 2.5
@export var follow_dist   : float = 4.0

# Vue pion (set_pawn_view) : un peu plus dézoomée que focus_on_square,
# mais plus que ce qui était hardcodé avant.
@export var pawn_view_dist   : float = 5.5
@export var pawn_view_height : float = 3.8

# Vitesses d'interpolation : normale en mode classique, plus lente quand on
# change de côté du plateau (transition coin) pour éviter l'effet violent.
@export var lerp_speed_normal : float = 6.0
@export var lerp_speed_corner : float = 2.5

var _target_pos  : Vector3 = Vector3.ZERO
var _target_rot  : Vector3 = Vector3.ZERO

# Centre du plateau (passé par sandbox_board.gd via set_global_view).
# Permet de garder la vue globale bien centrée même si le plateau n'est
# pas à l'origine du monde.
var _board_center : Vector3 = Vector3(-5, 0, -5)

var _current_lerp_speed : float = 6.0
var _last_side          : int   = -1

# Screen shake
var _shake_intensity : float = 0.0
var _shake_duration  : float = 0.0
var _shake_elapsed   : float = 0.0
var _shake_active    : bool  = false

func _ready() -> void:
	_target_pos = Vector3(_board_center.x, global_height, _board_center.z)
	_target_rot = Vector3(-90, 0, 0)
	position         = _target_pos
	rotation_degrees = _target_rot
	_current_lerp_speed = lerp_speed_normal

func _process(delta: float) -> void:
	var shake_offset := Vector3.ZERO

	if _shake_active:
		_shake_elapsed += delta
		var progress := _shake_elapsed / _shake_duration
		if progress >= 1.0:
			_shake_active = false
			_shake_elapsed = 0.0
		else:
			# Intensité décroissante
			var current_intensity := _shake_intensity * (1.0 - progress)
			shake_offset = Vector3(
				randf_range(-current_intensity, current_intensity),
				randf_range(-current_intensity, current_intensity),
				0.0
			)

	# Position : lerp linéaire classique
	position = position.lerp(_target_pos, _current_lerp_speed * delta) + shake_offset

	# Rotation : slerp via Basis (équivalent quaternion) → pas de flip d'Euler
	# quand on change de côté du plateau.
	var current_basis := Basis.from_euler(rotation)
	var target_basis  := Basis.from_euler(_target_rot * (PI / 180.0))
	var new_basis     := current_basis.slerp(target_basis, _current_lerp_speed * delta)
	rotation = new_basis.get_euler()


# ══════════════════════════════ API publique ═══════════════════════════════

func set_global_view(center: Vector3 = Vector3.INF) -> void:
	if center != Vector3.INF:
		_board_center = center
	_target_pos = Vector3(_board_center.x, global_height, _board_center.z)
	_target_rot = Vector3(-90, 0, 0)
	_current_lerp_speed = lerp_speed_normal
	_last_side = -1

func focus_on_square(square_pos: Vector3, side: int) -> void:
	_update_lerp_speed_for_side(side)
	_target_pos = _cam_pos_for_side(square_pos, side)
	_target_rot = _look_at_rot(_target_pos, square_pos + Vector3.UP * 1.5)

func set_pawn_view(pawn_pos: Vector3, side: int) -> void:
	_update_lerp_speed_for_side(side)
	var back : Vector3
	match side:
		0: back = Vector3( 0.0, 0.0,  pawn_view_dist)
		1: back = Vector3(-pawn_view_dist, 0.0, 0.0)
		2: back = Vector3( 0.0, 0.0, -pawn_view_dist)
		3: back = Vector3( pawn_view_dist, 0.0, 0.0)
		_: back = Vector3( 0.0, 0.0,  pawn_view_dist)

	_target_pos = pawn_pos + back + Vector3(0, pawn_view_height, 0)
	# === Changement important ===
	_target_rot = _look_at_rot(_target_pos, pawn_pos + Vector3(0, 1.8, 0))  # on regarde plus haut

## Déclenche un screen shake
## [param duration]  : durée en secondes
## [param intensity] : amplitude en unités monde (0.1 = léger, 0.5 = fort)
func shake(duration: float = 0.4, intensity: float = 0.2) -> void:
	_shake_duration  = duration
	_shake_intensity = intensity
	_shake_elapsed   = 0.0
	_shake_active    = true


# ══════════════════════════ Fonctions privées ══════════════════════════════

func _update_lerp_speed_for_side(side: int) -> void:
	if _last_side != -1 and _last_side != side:
		_current_lerp_speed = lerp_speed_corner
	else:
		_current_lerp_speed = lerp_speed_normal
	_last_side = side

func _cam_pos_for_side(sq: Vector3, side: int) -> Vector3:
	match side:
		0: return sq + Vector3(0.0,          follow_height,  follow_dist)
		1: return sq + Vector3(-follow_dist,  follow_height,  0.0        )
		2: return sq + Vector3(0.0,          follow_height, -follow_dist)
		3: return sq + Vector3(follow_dist,   follow_height,  0.0        )
		_: return sq + Vector3(0.0,          follow_height,  follow_dist)

func _look_at_rot(from_pos: Vector3, to_pos: Vector3) -> Vector3:
	var dir := (to_pos - from_pos).normalized()
	if dir.is_zero_approx():
		return Vector3(-90.0, 0.0, 0.0)
	var b := Basis.looking_at(dir, Vector3.UP)
	return b.get_euler() * (180.0 / PI)
