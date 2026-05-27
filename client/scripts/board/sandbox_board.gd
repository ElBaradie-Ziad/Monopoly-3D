# sandbox_board.gd
extends Node3D

signal intro_animation_finished

@onready var _camera           = $Camera3D
@onready var _building_manager = $BuildingManager

const PION1_SCENE : PackedScene = preload("res://design_raw/3d_models/Pion1/Pion1.tscn")
const PION2_SCENE : PackedScene = preload("res://design_raw/Pion2/Pion_2.tscn")
const PION3_SCENE : PackedScene = preload("res://design_raw/Pion3/Pion_3.tscn")
const PION4_SCENE : PackedScene = preload("res://design_raw/Pion4/Pion_4.tscn")
const PAWN_SCRIPT               = preload("res://scripts/board/pawn_controller.gd")
const PRISON_SCRIPT             = preload("res://scripts/board/prison_effect.gd")
const GO_SCRIPT                 = preload("res://scripts/board/go_effect.gd")
const HIGHLIGHTER_SCRIPT        = preload("res://scripts/board/property_highlighter.gd")
const DAY_NIGHT_SCRIPT          = preload("res://scripts/board/day_night_cycle.gd")
const RENT_HURT_SCRIPT          = preload("res://scripts/board/rent_hurt_effect.gd")

const PLAYER_COLORS : Array = [
	Color(0.95, 0.20, 0.20),   # Rouge
	Color(0.20, 0.45, 0.95),   # Bleu
	Color(0.20, 0.80, 0.30),   # Vert
	Color(0.98, 0.82, 0.15),   # Jaune
]

var square_positions : Array[Vector3] = []
var height_cases     : float = 1.66
var width_cases      : float = 1.007
var height_land      : float = 0.356
var _pawns         : Dictionary = {}
var _pawn_indices  : Dictionary = {}
var _pawn_cam_mode : bool       = false
var _followed_id   : int        = -1

# Mode "scroll libre" via la molette : on parcourt les cases sans bouger le pion.
# Reset automatiquement dès qu'on lance les dés ou qu'on clique sur un bouton vue.
var _scroll_active : bool = false
var _scroll_square : int  = 0

#Mode scroll libre sur mobile
var _touch_start_pos : Vector2 = Vector2.ZERO
var _swipe_threshold : float = 35.0  # Distance en pixels pour valider un balayage

# Verrou pendant les animations (déplacement, prison, GO, hurt) : bloque le
# scroll molette/flèches ET les boutons "Vue globale" / "Vue pion" pour éviter
# que le joueur déplace la caméra pendant qu'une animation se déroule.
var _animations_running : bool = false

var _prison_effect = null
var _go_effect     = null
var _highlighter   = null
var _day_night     = null
var _rent_hurt     = null

var _spin_from     : SpinBox = null
var _spin_to       : SpinBox = null
var _spin_property : SpinBox = null
var _spin_houses   : SpinBox = null
var _spin_owner    : SpinBox = null

var animation_player: AnimationPlayer = null
var cinematic_camera: Camera3D = null

func _ready() -> void:
	load_map(Global.current_map_name)

	await get_tree().process_frame  # Attendre que load_map() ait fini d'instancier Map1

	setup_square_positions()
	_building_manager.init(square_positions, width_cases, height_cases, height_land)
	# Centre la vue globale dès maintenant (avant la cinématique).
	_camera.set_global_view(compute_board_center())
	#Global.joueurs = [0, 1, 2, 3]  # ← ligne à commenter pour Ethan
	_spawn_all_pawns()
	_spawn_prison_effect()
	_spawn_go_effect()
	_spawn_highlighter()
	_spawn_day_night()
	_spawn_rent_hurt()
	Global.request_camera_global_view.connect(camera_vue_globale)
	Global.request_camera_pion_view.connect(camera_vue_pion)

	# Recherche des nodes après le chargement de la map
	animation_player = find_child("AnimationPlayer", true, false)
	cinematic_camera = find_child("Camera3D2", true, false)

	if animation_player and cinematic_camera:
		print("🎬 AnimationPlayer et Camera trouvés → Lancement de l'animation...")
		cinematic_camera.make_current()
		animation_player.play("Camera_Open")
		await animation_player.animation_finished
		print("✅ Animation cinématique terminée")
		_camera.make_current()
	else:
		push_error("❌ Impossible de trouver AnimationPlayer ou Camera3D2 dans Map1")
		_camera.make_current()

	intro_animation_finished.emit()

	_camera.make_current()
	#_build_debug_ui()


func load_map(map_name: String) -> void:
	var path : String = "res://assets/models/board/" + Global.current_map_name + ".tscn"
	var resource := load(path) as PackedScene
	if resource:
		add_child(resource.instantiate())
	else:
		push_warning("sandbox_board : carte introuvable : " + path)
		
		
		
func setup_square_positions() -> void:
	square_positions.clear()
	var cases_node = find_child("Cases", true, false)
	if cases_node == null:
		push_error("ERREUR : Le node 'Cases' est introuvable")
		return
	if "height_cases" in cases_node:
		height_cases = cases_node.height_cases
		width_cases  = cases_node.width_cases
		height_land  = cases_node.height_land
	else:
		push_warning("Le node Cases n'a pas le script map_dimensions.gd")
	var markers = cases_node.get_children()
	for marker in markers:
		square_positions.append(marker.global_position)
		print("Marker ", marker.name, " global_pos = ", marker.global_position)

func get_square_position(square_id: int) -> Vector3:
	if square_id >= 0 and square_id < square_positions.size():
		return square_positions[square_id]
	return Vector3.ZERO

func get_square_side(square_id: int) -> int:
	if square_id <= 10: return 0
	if square_id <= 19: return 1
	if square_id <= 30: return 2
	return 3

# Centre du plateau (moyenne de toutes les positions de cases) — utilisé
# pour centrer la vue globale même si le plateau n'est pas à l'origine.
func compute_board_center() -> Vector3:
	if square_positions.is_empty():
		return Vector3(-5, 0, -5)   # fallback raisonnable
	var sum := Vector3.ZERO
	for p in square_positions:
		sum += p
	return sum / square_positions.size()


func _spawn_all_pawns() -> void:
	print("spawn pawns, joueurs = ", Global.joueurs)
	var ids : Array = Global.joueurs if Global.joueurs.size() > 0 else [0]
	for i in range(ids.size()):
		var client_id : int = ids[i]
		_spawn_pawn_for(client_id, i)
	if ids.size() > 0:
		_followed_id = ids[0]

func _spawn_pawn_for(client_id: int, player_index: int) -> void:
	var scene : PackedScene
	match player_index % 4:
		0: scene = PION1_SCENE
		1: scene = PION2_SCENE
		2: scene = PION3_SCENE
		3: scene = PION4_SCENE
		_: scene = PION1_SCENE
	var tint : Color = Color(1, 1, 1)

	var wrapper := Node3D.new()
	wrapper.set_script(PAWN_SCRIPT)
	wrapper.name = "Pion_%d" % client_id
	add_child(wrapper)

	var mesh := scene.instantiate()
	wrapper.add_child(mesh)
	mesh.position = Vector3.ZERO
	mesh.rotation = Vector3.ZERO

	var scales : Array = [
		Vector3(0.3, 0.3, 0.3),
		Vector3(0.3, 0.3, 0.3),
		Vector3(0.3, 0.3, 0.3),
		Vector3(0.3, 0.3, 0.3),
	]
	mesh.scale = scales[player_index % scales.size()]

	if tint != Color(1, 1, 1):
		_apply_tint(mesh, tint)

	var pawn := wrapper as PawnController
	pawn.init(square_positions, width_cases, height_cases)
	pawn.pawn_index = player_index % 4
	pawn.teleport_to(0)

	pawn.step_reached.connect(func(sq, cid=client_id): _on_pion_step(sq, cid))
	pawn.movement_finished.connect(func(sq, cid=client_id): _on_pion_finished(sq, cid))

	# Pseudo flottant au-dessus du pion
	var username := "Joueur " + str(client_id)
	for p in Global.lobby_players:
		if int(p.get("clientID", -1)) == client_id:
			username = p.get("username", username)
			break
	pawn.set_player_name(username, PLAYER_COLORS[player_index % PLAYER_COLORS.size()])

	_pawns[client_id]        = pawn
	_pawn_indices[client_id] = player_index
	print("✅ Pion spawné pour joueur %d à la case 0" % client_id)

func _apply_tint(mesh_node: Node3D, tint: Color) -> void:
	for child in mesh_node.get_children():
		if child is MeshInstance3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = tint
			child.material_overlay = mat
		_apply_tint(child, tint)


func _spawn_prison_effect() -> void:
	var node := Node3D.new()
	node.set_script(PRISON_SCRIPT)
	node.name = "PrisonEffect"
	add_child(node)
	_prison_effect = node
	var dir_light : DirectionalLight3D = find_child("DirectionalLight3D", true, false)
	_prison_effect.init(_camera, dir_light)

func _spawn_go_effect() -> void:
	var node := Node3D.new()
	node.set_script(GO_SCRIPT)
	node.name = "GoEffect"
	add_child(node)
	_go_effect = node

func _spawn_highlighter() -> void:
	var node := Node3D.new()
	node.set_script(HIGHLIGHTER_SCRIPT)
	node.name = "PropertyHighlighter"
	add_child(node)
	_highlighter = node
	_highlighter.init(square_positions, width_cases, height_cases)

func _spawn_day_night() -> void:
	var node := Node.new()
	node.set_script(DAY_NIGHT_SCRIPT)
	node.name = "DayNightCycle"
	add_child(node)
	_day_night = node
	var dir_light : DirectionalLight3D = find_child("DirectionalLight3D", true, false)
	var env       : WorldEnvironment   = find_child("WorldEnvironment", true, false)
	if dir_light:
		_day_night.init(dir_light, env)
	else:
		push_warning("DayNightCycle : DirectionalLight3D introuvable")

func _spawn_rent_hurt() -> void:
	var node := Node.new()
	node.set_script(RENT_HURT_SCRIPT)
	node.name = "RentHurtEffect"
	add_child(node)
	_rent_hurt = node

func on_turn_end() -> void:
	if _day_night:
		await _day_night.on_turn_end()

## Illumine la case `sq_id` avec la couleur du joueur `client_id` pendant 1.2s.
## Fire-and-forget : ne pas attendre le retour.
func flash_destination(sq_id: int, client_id: int, duration: float = 1.2) -> void:
	if _highlighter == null:
		return
	var idx   : int   = Global.player_color_index.get(client_id, 0)
	var color : Color = PLAYER_COLORS[idx % PLAYER_COLORS.size()]
	_highlighter.flash_square_temp(sq_id, color, duration)


func camera_vue_globale() -> void:
	if _animations_running:
		return
	_pawn_cam_mode = false
	_scroll_active = false   # casse le mode scroll molette si actif
	_camera.set_global_view(compute_board_center())

func camera_vue_pion() -> void:
	if _animations_running:
		return
	_pawn_cam_mode = true          # on garde le flag pour les futurs déplacements
	_scroll_active = false

	var target_id : int = Global.current_client_id if _pawns.has(Global.current_client_id) else _followed_id
	if target_id in _pawns:
		_followed_id = target_id
		var sq = _pawns[target_id].current_square
		_camera.focus_on_square(square_positions[sq], get_square_side(sq))   # ← utilise focus_on_square

# Recadre la caméra sur le joueur indiqué (utilisé avant le lancer de dés
# notamment, et comme retour à la normale après un scroll molette).
func focus_camera_on_player(client_id: int) -> void:
	if not _pawns.has(client_id):
		return
	_followed_id = client_id
	_scroll_active = false
	var sq : int = _pawns[client_id].current_square
	if _pawn_cam_mode:
		_camera.set_pawn_view(square_positions[sq], get_square_side(sq))
	else:
		_camera.focus_on_square(square_positions[sq], get_square_side(sq))

func move_pion(client_id: int, from_sq: int, to_sq: int) -> void:
	if not _pawns.has(client_id):
		push_warning("move_pion: client_id %d inconnu" % client_id)
		return
	var pawn = _pawns[client_id]
	_followed_id = client_id
	# Tout déplacement annule un éventuel scroll libre et recadre sur le pion.
	_scroll_active = false
	_animations_running = true
	if not _pawn_cam_mode:
		_camera.focus_on_square(square_positions[from_sq], get_square_side(from_sq))
	else:
		_camera.set_pawn_view(square_positions[from_sq], get_square_side(from_sq))
	print("🎲 Joueur %d : case %d → case %d" % [client_id, from_sq, to_sq])
	await pawn.move_to(from_sq, to_sq)
	_animations_running = false

func move_pion_debug(from_sq: int, to_sq: int) -> void:
	if _pawns.is_empty():
		return
	var first_id : int = _pawns.keys()[0]
	await move_pion(first_id, from_sq, to_sq)

func play_prison_animation(client_id: int = -1) -> void:
	var pawn = _get_pawn(client_id)
	if pawn == null:
		return
	var prison_pos : Vector3 = square_positions[10]
	_animations_running = true
	_scroll_active = false
	# Recadre la caméra sur la prison pendant la sirène : grâce au lerp,
	# la caméra arrive avant que le pion soit téléporté visuellement.
	_followed_id = client_id if client_id != -1 else _followed_id
	if _pawn_cam_mode:
		_camera.set_pawn_view(prison_pos, get_square_side(10))
	else:
		_camera.focus_on_square(prison_pos, get_square_side(10))
	_prison_effect.play(pawn, prison_pos)
	await _prison_effect.finished
	pawn.current_square = 10
	_animations_running = false

func remove_prison_cage() -> void:
	_prison_effect.remove_cage()

func play_go_animation(is_my_turn: bool = true) -> void:
	if not is_my_turn:
		return
	_animations_running = true
	_go_effect.play(square_positions[0])
	await _go_effect.finished
	_animations_running = false

func highlight_property(property_id: int, owner_client_id: int) -> void:
	var nb_houses : int = Global.maisons_proprietes.get(property_id, 0)
	_highlighter.highlight_property(property_id, owner_client_id, nb_houses)
	# Une nouvelle gare/compagnie achetée modifie le loyer des autres
	# gares/compagnies du même groupe → on rafraîchit tous les labels.
	_highlighter.refresh_all_labels()

func clear_property_highlight(property_id: int) -> void:
	_highlighter.clear_property(property_id)

func clear_all_highlights() -> void:
	_highlighter.clear_all()

func place_buildings(property_id: int, nb_houses: int, has_hotel: bool, owner_client_id: int) -> void:
	_building_manager.update_buildings(property_id, nb_houses, has_hotel, owner_client_id)
	# Le loyer dépend du nombre de maisons → on met à jour juste le label
	# (le quad de surbrillance existe déjà, pas la peine de le redessiner).
	_highlighter.update_label(property_id, owner_client_id, nb_houses)

func clear_buildings(property_id: int) -> void:
	_building_manager.clear_property(property_id)

# ── Animation de faillite : pion tourne, s'enfonce, disparaît ────────────────
func play_bankruptcy_animation(client_id: int) -> void:
	var pawn = _get_pawn(client_id)
	if pawn == null:
		return

	_animations_running = true

	# 1. Caméra sur le pion condamné
	focus_camera_on_player(client_id)

	# 2. Flash écran noir
	# mouse_filter IGNORE → le rect ne bloque jamais les clics (même transparent).
	# tween_callback pour queue_free → le canvas se nettoie même si la scène
	# change avant la fin de l'animation (sinon il reste sur root et bloque le menu).
	var canvas := CanvasLayer.new()
	var rect   := ColorRect.new()
	rect.color        = Color(0.0, 0.0, 0.0, 0.0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	get_tree().root.add_child(canvas)
	var flash_tw := canvas.create_tween()
	flash_tw.tween_property(rect, "color:a", 0.6,  0.3).set_trans(Tween.TRANS_QUAD)
	flash_tw.tween_property(rect, "color:a", 0.0,  1.2).set_trans(Tween.TRANS_QUAD)
	flash_tw.tween_callback(canvas.queue_free)  # nettoyage garanti même après changement de scène

	# 3. Pion : spin rapide + enfoncement simultanés (parallel tween)
	var sink_target : Vector3 = pawn.global_position + Vector3(0, -2.5, 0)

	var motion_tw : Tween = pawn.create_tween()
	motion_tw.set_parallel(true)
	# rotation Y × 4 tours en 1.5 s
	motion_tw.tween_property(pawn, "rotation:y",
		pawn.rotation.y + TAU * 4.0, 1.5) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# enfoncement progressif
	motion_tw.tween_property(pawn, "global_position", sink_target, 1.8) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await motion_tw.finished

	_animations_running = false

# ── Séquence de victoire : lumières dorées + bâtiments glorifiés ─────────────
func play_victory_sequence(winner_id: int) -> void:
	_animations_running = true

	# 1. Shake de caméra
	if _camera.has_method("shake"):
		_camera.shake(1.2, 0.5)

	# 2. Flash doré bref
	var canvas := CanvasLayer.new()
	var rect   := ColorRect.new()
	rect.color = Color(1.0, 0.85, 0.0, 0.0)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	get_tree().root.add_child(canvas)
	var flash_tw := canvas.create_tween()
	flash_tw.tween_property(rect, "color:a", 0.45, 0.25).set_trans(Tween.TRANS_QUAD)
	flash_tw.tween_property(rect, "color:a", 0.0,  0.8).set_trans(Tween.TRANS_QUAD)
	flash_tw.tween_callback(canvas.queue_free)

	# 3. Surbrillance dorée de toutes les propriétés du gagnant
	for prop_id in Global.proprietes_joueurs.keys():
		if Global.proprietes_joueurs[prop_id] == winner_id:
			var nb_h : int = Global.maisons_proprietes.get(prop_id, 0)
			_highlighter.highlight_property(prop_id, winner_id, nb_h)

	# 4. Scale-up des bâtiments du gagnant (effet "empire")
	_building_manager.glorify_player_buildings(winner_id)

	# 5. Zoom caméra sur le pion gagnant
	await get_tree().create_timer(0.5).timeout
	focus_camera_on_player(winner_id)

	# 6. Rebond de victoire du pion gagnant
	var pawn : Node3D = _get_pawn(winner_id)
	if pawn != null:
		var base_y : float = pawn.global_position.y
		for _i in range(3):
			var bounce_tw : Tween = pawn.create_tween()
			bounce_tw.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			bounce_tw.tween_property(pawn, "global_position:y", base_y + 0.6, 0.25)
			bounce_tw.tween_property(pawn, "global_position:y", base_y,       0.35)
			await bounce_tw.finished

	_animations_running = false

func play_rent_hurt(victim_id: int, owner_id: int = -1) -> void:
	var pawn = _get_pawn(victim_id)
	if pawn == null:
		return
	var owner_pos : Vector3 = pawn.global_position + Vector3(1, 0, 0)
	if owner_id != -1 and _pawns.has(owner_id):
		owner_pos = _pawns[owner_id].global_position
	_animations_running = true
	await _rent_hurt.play(pawn, owner_pos)
	_animations_running = false


func _on_pion_step(sq: int, client_id: int) -> void:
	if client_id == Global.my_client_id or client_id == _followed_id:
		if _pawn_cam_mode:
			_camera.set_pawn_view(square_positions[sq], get_square_side(sq))
		else:
			_camera.focus_on_square(square_positions[sq], get_square_side(sq))
		if sq == 0:
			play_go_animation(true)

func _on_pion_finished(sq: int, client_id: int) -> void:
	print("✅ Joueur %d arrivé à la case %d" % [client_id, sq])


func _get_pawn(client_id: int):
	if client_id == -1:
		if Global.my_client_id in _pawns:
			return _pawns[Global.my_client_id]
		elif not _pawns.is_empty():
			return _pawns[_pawns.keys()[0]]
		return null
	if _pawns.has(client_id):
		return _pawns[client_id]
	return null


func _build_debug_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "DebugUI"
	add_child(canvas)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	vbox.offset_left  = -220.0
	vbox.offset_right = -10.0
	vbox.add_theme_constant_override("separation", 8)
	root.add_child(vbox)

	var btn_global := Button.new()
	btn_global.text       = "🌍 Vue globale"
	btn_global.focus_mode = Control.FOCUS_NONE
	btn_global.pressed.connect(func(): camera_vue_globale())
	vbox.add_child(btn_global)

	var btn_pawn := Button.new()
	btn_pawn.text       = "🎮 Vue pion"
	btn_pawn.focus_mode = Control.FOCUS_NONE
	btn_pawn.pressed.connect(func(): camera_vue_pion())
	vbox.add_child(btn_pawn)

	vbox.add_child(_make_separator("── Déplacer le pion ──"))

	var hbox_from := HBoxContainer.new()
	vbox.add_child(hbox_from)
	hbox_from.add_child(_make_label_ui("Départ  : "))
	_spin_from = _make_spinbox(0, 39, 0)
	hbox_from.add_child(_spin_from)

	var hbox_to := HBoxContainer.new()
	vbox.add_child(hbox_to)
	hbox_to.add_child(_make_label_ui("Arrivée : "))
	_spin_to = _make_spinbox(0, 39, 6)
	hbox_to.add_child(_spin_to)

	var hbox_player := HBoxContainer.new()
	vbox.add_child(hbox_player)
	hbox_player.add_child(_make_label_ui("Joueur  : "))
	var spin_player := _make_spinbox(0, 3, 0)
	hbox_player.add_child(spin_player)

	var btn_move := Button.new()
	btn_move.text       = "▶  Lancer l'animation"
	btn_move.focus_mode = Control.FOCUS_NONE
	btn_move.pressed.connect(func():
		var ids : Array = Global.joueurs if Global.joueurs.size() > 0 else [0]
		var idx : int = int(spin_player.value) % ids.size()
		var cid : int = ids[idx]
		move_pion(cid, int(_spin_from.value), int(_spin_to.value))
	)
	vbox.add_child(btn_move)

	vbox.add_child(_make_separator("── Bâtiment de test ──"))

	var hbox_prop := HBoxContainer.new()
	vbox.add_child(hbox_prop)
	hbox_prop.add_child(_make_label_ui("Case     : "))
	_spin_property = _make_spinbox(0, 39, 1)
	hbox_prop.add_child(_spin_property)

	var hbox_houses := HBoxContainer.new()
	vbox.add_child(hbox_houses)
	hbox_houses.add_child(_make_label_ui("Maisons  : "))
	_spin_houses = _make_spinbox(0, 4, 1)
	hbox_houses.add_child(_spin_houses)

	var hbox_owner := HBoxContainer.new()
	vbox.add_child(hbox_owner)
	hbox_owner.add_child(_make_label_ui("Joueur   : "))
	_spin_owner = _make_spinbox(0, 3, 0)
	hbox_owner.add_child(_spin_owner)

	var btn_house := Button.new()
	btn_house.text       = "🏠 Construire maisons"
	btn_house.focus_mode = Control.FOCUS_NONE
	btn_house.pressed.connect(func():
		place_buildings(int(_spin_property.value), int(_spin_houses.value), false, int(_spin_owner.value))
	)
	vbox.add_child(btn_house)

	var btn_hotel := Button.new()
	btn_hotel.text       = "🏨 Construire hôtel"
	btn_hotel.focus_mode = Control.FOCUS_NONE
	btn_hotel.pressed.connect(func():
		place_buildings(int(_spin_property.value), 0, true, int(_spin_owner.value))
	)
	vbox.add_child(btn_hotel)

	vbox.add_child(_make_separator("── Propriété test ──"))

	var hbox_hl := HBoxContainer.new()
	vbox.add_child(hbox_hl)
	hbox_hl.add_child(_make_label_ui("Case : "))
	var spin_hl := _make_spinbox(0, 39, 1)
	hbox_hl.add_child(spin_hl)

	var hbox_hl_owner := HBoxContainer.new()
	vbox.add_child(hbox_hl_owner)
	hbox_hl_owner.add_child(_make_label_ui("Joueur : "))
	var spin_hl_owner := _make_spinbox(0, 3, 0)
	hbox_hl_owner.add_child(spin_hl_owner)

	var btn_hl := Button.new()
	btn_hl.text       = "💡 Colorier case"
	btn_hl.focus_mode = Control.FOCUS_NONE
	btn_hl.pressed.connect(func(): highlight_property(int(spin_hl.value), int(spin_hl_owner.value)))
	vbox.add_child(btn_hl)

	var btn_hl_clear := Button.new()
	btn_hl_clear.text       = "🚫 Effacer couleur"
	btn_hl_clear.focus_mode = Control.FOCUS_NONE
	btn_hl_clear.pressed.connect(func(): clear_property_highlight(int(spin_hl.value)))
	vbox.add_child(btn_hl_clear)

	vbox.add_child(_make_separator("── Hurt test ──"))

	var hbox_hurt := HBoxContainer.new()
	vbox.add_child(hbox_hurt)
	hbox_hurt.add_child(_make_label_ui("Victime : "))
	var spin_hurt_victim := _make_spinbox(0, 3, 0)
	hbox_hurt.add_child(spin_hurt_victim)

	var hbox_hurt2 := HBoxContainer.new()
	vbox.add_child(hbox_hurt2)
	hbox_hurt2.add_child(_make_label_ui("Owner   : "))
	var spin_hurt_owner := _make_spinbox(0, 3, 1)
	hbox_hurt2.add_child(spin_hurt_owner)

	var btn_hurt := Button.new()
	btn_hurt.text       = "💥 Test Hurt"
	btn_hurt.focus_mode = Control.FOCUS_NONE
	btn_hurt.pressed.connect(func():
		var ids : Array = Global.joueurs if Global.joueurs.size() > 0 else [0, 1, 2, 3]
		var victim : int = ids[int(spin_hurt_victim.value) % ids.size()]
		var owner  : int = ids[int(spin_hurt_owner.value)  % ids.size()]
		play_rent_hurt(victim, owner)
	)
	vbox.add_child(btn_hurt)

	vbox.add_child(_make_separator("── Day/Night test ──"))

	var btn_night := Button.new()
	btn_night.text       = "🌙 Nuit"
	btn_night.focus_mode = Control.FOCUS_NONE
	btn_night.pressed.connect(func(): _day_night._transition_to_night())
	vbox.add_child(btn_night)

	var btn_day := Button.new()
	btn_day.text       = "☀️ Jour"
	btn_day.focus_mode = Control.FOCUS_NONE
	btn_day.pressed.connect(func(): _day_night._transition_to_day())
	vbox.add_child(btn_day)

	vbox.add_child(_make_separator("── GO test ──"))

	var btn_go_fx := Button.new()
	btn_go_fx.text       = "⭐ Test GO"
	btn_go_fx.focus_mode = Control.FOCUS_NONE
	btn_go_fx.pressed.connect(func(): play_go_animation(true))
	vbox.add_child(btn_go_fx)

	vbox.add_child(_make_separator("── Prison test ──"))

	var btn_prison := Button.new()
	btn_prison.text       = "🚔 Test Prison"
	btn_prison.focus_mode = Control.FOCUS_NONE
	btn_prison.pressed.connect(func(): play_prison_animation())
	vbox.add_child(btn_prison)

	var btn_remove_cage := Button.new()
	btn_remove_cage.text       = "🔓 Sortir de prison"
	btn_remove_cage.focus_mode = Control.FOCUS_NONE
	btn_remove_cage.pressed.connect(func(): remove_prison_cage())
	vbox.add_child(btn_remove_cage)

	var btn_clear := Button.new()
	btn_clear.text       = "🗑  Effacer case"
	btn_clear.focus_mode = Control.FOCUS_NONE
	btn_clear.pressed.connect(func(): clear_buildings(int(_spin_property.value)))
	vbox.add_child(btn_clear)


func _make_separator(txt: String) -> Label:
	var l := Label.new(); l.text = txt; return l

func _make_label_ui(txt: String) -> Label:
	var l := Label.new(); l.text = txt; return l

func _make_spinbox(mn: int, mx: int, val: int) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = mn; s.max_value = mx; s.value = val
	return s

func _input(event: InputEvent) -> void:
	if _animations_running:
		return

	# ── GESTION PC ──
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_camera(+1)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_camera(-1)
			return
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_RIGHT:
			_scroll_camera(-1)
			return
		elif event.keycode == KEY_LEFT:
			_scroll_camera(+1)
			return
			
	# ── GESTION MOBILE (Swipe inversé) ──
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start_pos = event.position
		else:
			var touch_end_pos : Vector2 = event.position
			var swipe_vector := touch_end_pos - _touch_start_pos
			
			if abs(swipe_vector.x) > abs(swipe_vector.y):
				if abs(swipe_vector.x) > _swipe_threshold:
					if swipe_vector.x > 0:
						_scroll_camera(+1) # Inversé : Glisser vers la droite avance
					else:
						_scroll_camera(-1) # Inversé : Glisser vers la gauche recule

# ══════════════════════════ Scroll caméra ═══════════════════════════════
# Molette UP / flèche DROITE → caméra avance d'une case (case + 1)
# Molette DOWN / flèche GAUCHE → caméra recule d'une case (case - 1)
# Le retour automatique se fait dans move_pion() / focus_camera_on_player()
# / camera_vue_globale() / camera_vue_pion().

func _unhandled_input(event: InputEvent) -> void:
	# Bloque toute navigation caméra pendant qu'une animation est en cours.
	if _animations_running:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_camera(+1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_camera(-1)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_RIGHT:
			_scroll_camera(-1)
		elif event.keycode == KEY_LEFT:
			_scroll_camera(+1)
			
	#Gestion mobile (swipe horizontal)
	if event is InputEventScreenTouch:
		if event.pressed: #on enregistre la position de départ du doigt
			_touch_start_pos = event.position
		else:
			#quand le joueur relève le doigt
			var touch_end_pos = event.position
			var swipe_vector = touch_end_pos - _touch_start_pos
			
			if abs(swipe_vector.x) >abs(swipe_vector.y):
				if abs(swipe_vector.x) >  _swipe_threshold:
					if swipe_vector.x > 0:
						#swipe vers la droite -> on recule d'une case
						_scroll_camera(-1)
					else:
						#swipe vers la gauche, on avance
						_scroll_camera(+1)
						
func _scroll_camera(direction: int) -> void:
	if square_positions.is_empty():
		return
	# Initialise la position de scroll sur le pion suivi à la première molette.
	if not _scroll_active:
		var followed_pawn = _pawns.get(_followed_id)
		_scroll_square = followed_pawn.current_square if followed_pawn else 0
		_scroll_active = true
	_scroll_square = (_scroll_square + direction + 40) % 40
	var pos  : Vector3 = square_positions[_scroll_square]
	var side : int     = get_square_side(_scroll_square)
	print("🖱️ Scroll molette → case ", _scroll_square, " (côté ", side, ")")
	if _pawn_cam_mode:
		_camera.set_pawn_view(pos, side)
	else:
		_camera.focus_on_square(pos, side)
