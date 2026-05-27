# pawn_camera.gd
extends Camera3D

# Référence au plateau pour obtenir les positions des cases
@onready var board = get_parent()

# Paramètres de la caméra
var camera_height: float = 5.0   # Hauteur au-dessus du pion
var camera_distance: float = 7.0  # Distance derrière le pion
var camera_tilt: float = -30.0   # Angle d'inclinaison

# Suivi
var current_square: int = 0
var current_angle: float = -90.0  # Angle actuel de la caméra (0, 90, 180, -90)
var is_following: bool = true
var follow_speed: float = 3.0

# Position et rotation cibles
var target_position: Vector3 = Vector3.ZERO
var target_rotation: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Position initiale sur la case 0
	current_angle = 0.0  # Commence par regarder vers le haut
	focus_on_square(0)
	print("✅ Pawn camera ready")

func _process(delta: float) -> void:
	if is_following:
		# Interpolation douce
		position = position.lerp(target_position, follow_speed * delta)
		rotation_degrees = rotation_degrees.lerp(target_rotation, follow_speed * delta)
	
	# Contrôles debug
	handle_debug_controls()

func handle_debug_controls() -> void:
	# Flèche DROITE : case suivante
	if Input.is_action_just_pressed("ui_right"):
		focus_on_square((current_square + 1) % 40)
	
	# Flèche GAUCHE : case précédente
	if Input.is_action_just_pressed("ui_left"):
		focus_on_square((current_square - 1 + 40) % 40)
	
	# P : Switch to pawn camera
	if Input.is_action_just_pressed("ui_page_up"):  # Touche Page Up
		make_current()
		print("📷 Switched to PAWN camera")
	
	# V : Vue globale (switch to board camera)
	if Input.is_key_pressed(KEY_V):
		switch_to_global_view()
		print("📷 Switched to GLOBAL view")

# Suivre une case et changer d'angle seulement aux coins
func focus_on_square(square_id: int) -> void:
	if square_id < 0 or square_id >= 40:
		return
	
	current_square = square_id
	
	# Obtenir la position de la case
	var square_pos = board.get_square_position(square_id)
	
	# Vérifier si c'est un coin → changer l'angle
	if square_id % 10 == 0:
		update_camera_angle_at_corner(square_id)
		print("🔄 Corner detected at square ", square_id, " - New angle: ", current_angle, "°")
	
	# Calculer la position de la caméra en fonction de l'angle actuel
	var offset = get_camera_offset_from_angle()
	target_position = square_pos + offset
	
	# La caméra regarde toujours vers le centre du plateau
	var look_direction = (Vector3.ZERO - target_position).normalized()
	var target_basis = Basis.looking_at(look_direction, Vector3.UP)
	target_rotation = target_basis.get_euler() * 180.0 / PI  # Convertir en degrés
	
	is_following = true
	
	print("📷 Pawn camera on square ", square_id)

# Mettre à jour l'angle de la caméra aux coins
func update_camera_angle_at_corner(square_id: int) -> void:
	match square_id:
		0:   # Coin bas-droit (GO)
			current_angle = 0.0    # Regarde vers le haut (nord)
		10:  # Coin bas-gauche (Visite)
			current_angle = 90.0   # Regarde vers la droite (est)
		20:  # Coin haut-gauche (Parc gratuit)
			current_angle = 180.0  # Regarde vers le bas (sud)
		30:  # Coin haut-droit (Allez en prison)
			current_angle = -90.0  # Regarde vers la gauche (ouest)

# Calculer l'offset de la caméra selon l'angle actuel
func get_camera_offset_from_angle() -> Vector3:
	var rad = deg_to_rad(current_angle)
	
	# La caméra est toujours "derrière" selon la direction actuelle
	var back_direction = Vector3(-sin(rad), 0, -cos(rad))
	
	return back_direction * camera_distance + Vector3(0, camera_height, 0)

# Suivre le mouvement d'un pion (animation)
func follow_pawn_movement(from_square: int, to_square: int, duration: float = 2.0) -> void:
	# Calculer le nombre de cases à parcourir
	var steps = (to_square - from_square + 40) % 40
	
	# Animer case par case
	for i in range(steps + 1):
		var square = (from_square + i) % 40
		focus_on_square(square)
		await get_tree().create_timer(duration / steps).timeout
	
	print("🎥 Pawn movement complete: ", from_square, " → ", to_square)

# Téléporter directement à une case
func teleport_to_square(square_id: int) -> void:
	focus_on_square(square_id)
	# Applique instantanément sans interpolation
	position = target_position
	rotation_degrees = target_rotation

# Suivre un joueur spécifique
func follow_player(player_id: int, square_id: int) -> void:
	focus_on_square(square_id)
	print("📷 Following player ", player_id, " on square ", square_id)

# Vue globale (active la board camera)
func switch_to_global_view() -> void:
	# Désactive cette caméra et active la board camera
	var board_cam = get_parent().get_node("Camera3D")
	if board_cam:
		board_cam.make_current()
		print("📷 Switched to Board Camera (global view)")

# Réinitialiser
func reset_camera() -> void:
	current_square = 0
	current_angle = 0.0
	focus_on_square(0)
	print("🔄 Pawn camera reset")
