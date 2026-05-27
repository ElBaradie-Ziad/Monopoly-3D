# board_camera.gd
extends Camera3D

# Référence au plateau pour obtenir les positions des cases
@onready var board = get_parent()

# Paramètres de la caméra
var camera_height: float = 20.0  # Hauteur de la caméra
var camera_distance: float = 10.0  # Distance depuis le centre du plateau
var camera_tilt: float = -55.0  # Angle d'inclinaison vers le bas

# Suivi du pion
var current_square: int = 0  # Case actuelle suivie
var is_following: bool = false  # Mode suivi activé
var follow_speed: float = 3.0  # Vitesse de transition entre cases

# Position et rotation cibles
var target_position: Vector3 = Vector3.ZERO
var target_rotation: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Position initiale : vue globale
	position = Vector3(0, 35, -5)
	rotation_degrees = Vector3(-90, 0, 0)
	print("✅ Board camera ready")

func _process(delta: float) -> void:
	if is_following:
		# Interpolation douce vers la position et rotation cibles
		position = position.lerp(target_position, follow_speed * delta)
		rotation_degrees = rotation_degrees.lerp(target_rotation, follow_speed * delta)
	
	# Contrôles au clavier (pour test)
	handle_debug_controls()

func handle_debug_controls() -> void:
	# Flèche DROITE : case suivante
	if Input.is_action_just_pressed("ui_right"):
		focus_on_square((current_square + 1) % 40)
	
	# Flèche GAUCHE : case précédente
	if Input.is_action_just_pressed("ui_left"):
		focus_on_square((current_square - 1 + 40) % 40)
	
	# Espace : toggle mode suivi
	if Input.is_action_just_pressed("ui_accept"):
		toggle_follow_mode()
	
	# V : Vue globale
	if Input.is_key_pressed(KEY_V):
		switch_to_global_view()

# Fonction principale : Positionner la caméra sur le côté du plateau où se trouve la case
func focus_on_square(square_id: int) -> void:
	if square_id < 0 or square_id >= 40:
		push_error("❌ Invalid square_id: ", square_id)
		return
	
	current_square = square_id
	
	# Déterminer le côté du plateau
	var side = get_board_side(square_id)
	
	# Positionner la caméra au centre du côté (pas sur la case individuelle)
	target_position = get_camera_position_for_side(side)
	
	# Calculer la rotation pour que la caméra regarde le centre du plateau
	var look_direction = (Vector3.ZERO - target_position).normalized()
	var target_basis = Basis.looking_at(look_direction, Vector3.UP)
	target_rotation = target_basis.get_euler() * 180.0 / PI  # Convertir en degrés
	
	is_following = true
	
	print("📷 Camera focusing on side ", get_side_name(side), " for square ", square_id)

# Obtenir la position fixe de la caméra pour un côté donné
func get_camera_position_for_side(side: int) -> Vector3:
	match side:
		0:  # Bas : caméra au centre du côté sud
			return Vector3(0, camera_height, -camera_distance)
		1:  # Gauche : caméra au centre du côté ouest
			return Vector3(-camera_distance, camera_height, 0)
		2:  # Haut : caméra au centre du côté nord
			return Vector3(0, camera_height, camera_distance)
		3:  # Droite : caméra au centre du côté est
			return Vector3(camera_distance, camera_height, 0)
		_:
			return Vector3(0, camera_height, -camera_distance)

# Déterminer sur quel côté du plateau se trouve la case
func get_board_side(square_id: int) -> int:
	# Côtés : 0=Bas, 1=Gauche, 2=Haut, 3=Droite
	if square_id >= 0 and square_id <= 10:
		return 0  # Bas (cases 0-10)
	elif square_id >= 11 and square_id <= 19:
		return 1  # Gauche (cases 11-19)
	elif square_id >= 20 and square_id <= 30:
		return 2  # Haut (cases 20-30)
	else:
		return 3  # Droite (cases 31-39)

# Obtenir le nom du côté (pour debug)
func get_side_name(side: int) -> String:
	match side:
		0: return "BAS"
		1: return "GAUCHE"
		2: return "HAUT"
		3: return "DROITE"
		_: return "UNKNOWN"

# Suivre un pion spécifique (par son ID de joueur)
func follow_pawn(player_id: int, square_id: int) -> void:
	focus_on_square(square_id)
	print("📷 Following player ", player_id, " on square ", square_id)

# Basculer le mode suivi on/off
func toggle_follow_mode() -> void:
	is_following = !is_following
	if is_following:
		print("📷 Follow mode: ON")
		focus_on_square(current_square)
	else:
		print("📷 Follow mode: OFF")

# Vue globale du plateau (vue d'ensemble)
func switch_to_global_view() -> void:
	is_following = false
	target_position = Vector3(0, 35, -5)
	target_rotation = Vector3(-90, 0, 0)
	
	# Transition rapide
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_position, 0.5)
	tween.tween_property(self, "rotation_degrees", target_rotation, 0.5)
	
	print("📷 Switched to global view")

# Déplacement fluide vers une case (animation)
func animate_to_square(square_id: int, duration: float = 1.0) -> void:
	if square_id < 0 or square_id >= 40:
		return
	
	# Obtenir la position fixe du côté
	var side = get_board_side(square_id)
	var new_position = get_camera_position_for_side(side)
	
	# Calculer la rotation pour regarder le centre
	var look_direction = (Vector3.ZERO - new_position).normalized()
	var new_basis = Basis.looking_at(look_direction, Vector3.UP)
	var new_rotation = new_basis.get_euler() * 180.0 / PI
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", new_position, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation_degrees", new_rotation, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	current_square = square_id
	print("🎬 Animating camera to side ", get_side_name(side))

# Suivre le mouvement d'un pion (de case A à case B)
func follow_pawn_movement(from_square: int, to_square: int, duration: float = 2.0) -> void:
	# Animation fluide qui suit le pion pendant son déplacement
	animate_to_square(from_square, 0.3)  # D'abord focus sur la case de départ
	
	await get_tree().create_timer(0.5).timeout
	
	animate_to_square(to_square, duration)  # Puis suit jusqu'à l'arrivée
	print("🎥 Following pawn movement from ", from_square, " to ", to_square)

# Réinitialiser la caméra
func reset_camera() -> void:
	is_following = false
	current_square = 0
	switch_to_global_view()
	print("🔄 Camera reset")
