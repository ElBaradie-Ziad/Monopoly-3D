# building_manager.gd
extends Node3D

const HOUSE_SCENE : PackedScene = preload("res://design_raw/3d_models/House/HouseSpawnEffect.tscn")

const PLAYER_COLORS : Array = [
	Color(0.9, 0.15, 0.15),
	Color(0.15, 0.35, 0.9),
	Color(0.15, 0.75, 0.25),
	Color(0.95, 0.80, 0.10),
]
const HOTEL_COLOR : Color = Color(0.6, 0.05, 0.05)

const HOUSE_FINAL_SCALE : Vector3 = Vector3(0.01, 0.01, 0.01)
const HOTEL_FINAL_SCALE : Vector3 = Vector3(0.018, 0.018, 0.018)

# Espacement entre les maisons sur une même case (axe parallèle au bandeau)
const HOUSE_GAP : float = 0.25

var _buildings : Dictionary = {}

var _square_positions : Array[Vector3] = []
var _size_small : float = 0
var _size_big : float = 0
var _height_land : float = 0

func init(square_positions: Array[Vector3], small_size: float, big_size: float, height_land : float) -> void:
	_square_positions = square_positions
	_size_small = small_size
	_size_big = big_size
	_height_land = height_land

func update_buildings(property_id: int, nb_houses: int, has_hotel: bool, owner_client_id: int) -> void:
	clear_property(property_id)

	if property_id < 0 or property_id >= _square_positions.size():
		push_error("BuildingManager: property_id invalide : %d" % property_id)
		return

	var base_pos : Vector3 = _square_positions[property_id]
	var color : Color = _get_player_color(owner_client_id)

	if has_hotel:
		var offset : Vector3 = _get_house_offset(property_id, 0, 1)
		_spawn_building(property_id, base_pos + offset, HOTEL_FINAL_SCALE, HOTEL_COLOR, true)
	else:
		for i in range(nb_houses):
			var offset : Vector3 = _get_house_offset(property_id, i, nb_houses)
			_spawn_building(property_id, base_pos + offset, HOUSE_FINAL_SCALE, color, false)

func clear_property(property_id: int) -> void:
	if _buildings.has(property_id):
		for node in _buildings[property_id]:
			if is_instance_valid(node):
				node.queue_free()
		_buildings.erase(property_id)

func clear_all() -> void:
	for pid in _buildings.keys():
		clear_property(pid)

func _spawn_building(property_id: int, pos: Vector3, scale_v: Vector3, color: Color, is_hotel: bool) -> void:
	var node := HOUSE_SCENE.instantiate()
	node.final_scale = scale_v

	if (_get_side(property_id) % 2 == 1):
		node.rotation_degrees.y = 90

	add_child(node)

	await get_tree().process_frame

	node.global_position = pos

	var mesh_node : MeshInstance3D = node.get_node_or_null("HouseMesh")
	if mesh_node:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		if is_hotel:
			mat.emission_enabled = true
			mat.emission = color * 0.3
		mesh_node.material_override = mat

	if not _buildings.has(property_id):
		_buildings[property_id] = []
	_buildings[property_id].append(node)

func _get_player_color(client_id: int) -> Color:
	var idx : int = Global.player_color_index.get(client_id, 0)
	return PLAYER_COLORS[idx % PLAYER_COLORS.size()]

## Retourne l'offset vers le bandeau coloré selon le côté de la case
func _get_band_offset(property_id: int) -> Vector3:
	match _get_side(property_id):
		0: return Vector3(0, 0, 0)   # Bas   → Z- (vers intérieur)
		1: return Vector3(0, 0, 0)   # Gauche→ X+ (vers intérieur)
		2: return Vector3(0, 0, 0)   # Haut  → Z+ (vers intérieur)
		3: return Vector3(0, 0, 0)   # Droite→ X- (vers intérieur)
	return Vector3.ZERO

## Retourne l'offset combiné : espacement entre maisons + vers bandeau
func _get_house_offset(property_id: int, house_index: int, nb_houses : int) -> Vector3:
	#print("%d", ((house_index + 1.0)/(nb_houses + 1.0)))
	var x_offset = ((house_index + 1.0)/(nb_houses + 1.0)) * _size_small
	var z_offset = _height_land/2

	# Sur les côtés gauche/droite, l'axe d'espacement devient Z
	var side : int = _get_side(property_id)
	if side == 0:
		return Vector3(x_offset, 0, z_offset)
	if side == 1:
		return Vector3(-z_offset, 0, x_offset)
	elif side == 2:
		return Vector3(-x_offset, 0, -z_offset)

	return Vector3(z_offset, 0, -x_offset)

func _get_side(sq: int) -> int:
	if sq < 10: return 0
	if sq < 20: return 1
	if sq < 30: return 2
	return 3

# ── Séquence de victoire : teinte dorée + scale-up des bâtiments du gagnant ──
func glorify_player_buildings(winner_client_id: int) -> void:
	for prop_id in _buildings.keys():
		if Global.proprietes_joueurs.get(prop_id, -1) != winner_client_id:
			continue
		for node in _buildings[prop_id]:
			if not is_instance_valid(node):
				continue
			# Teinte dorée sur le mesh
			var mesh_node : MeshInstance3D = node.get_node_or_null("HouseMesh")
			if mesh_node:
				var mat := StandardMaterial3D.new()
				mat.albedo_color      = Color(1.0, 0.82, 0.1)   # or
				mat.emission_enabled  = true
				mat.emission          = Color(1.0, 0.72, 0.0) * 0.6
				mesh_node.material_override = mat
			# Scale-up vers le haut avec rebond
			var tw : Tween = node.create_tween()
			tw.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			tw.tween_property(node, "scale", node.scale * 2.2, 0.8)
