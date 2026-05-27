# property_highlighter.gd
extends Node3D

const PLAYER_COLORS : Array = [
	Color(0.9, 0.15, 0.15, 0.45),
	Color(0.15, 0.35, 0.9,  0.45),
	Color(0.15, 0.75, 0.25, 0.45),
	Color(0.95, 0.80, 0.10, 0.45),
]

# Mêmes couleurs que PLAYER_COLORS mais en alpha plein, pour le texte des labels.
const PLAYER_LABEL_COLORS : Array = [
	Color(0.95, 0.20, 0.20),
	Color(0.20, 0.45, 0.95),
	Color(0.20, 0.80, 0.30),
	Color(0.98, 0.82, 0.15),
]

@export var quad_height_offset  : float = 0.05
@export var label_height_offset : float = 0.5
@export var fade_duration       : float = 0.5
@export var panel_font_size     : int   = 22

# Dimensions de la texture pancarte (en pixels). Le panneau aura une largeur
# en world units égale à _width_cases, donc pixel_size = _width_cases / TEX_W.
const TEX_W : int = 200
const TEX_H : int = 140

var _quads            : Dictionary     = {}
var _flash_quads      : Dictionary     = {}   # sq_id → MeshInstance3D (flash temporaire)
var _labels           : Dictionary     = {}   # property_id → Node3D (container avec Sprite3D + Label3D)
var _panel_tex_cache  : Dictionary     = {}   # clé couleur → ImageTexture (cache pour éviter de regénérer)
var _width_cases      : float          = 1.007
var _height_cases     : float          = 1.66
var _height_land      : float          = 0.356
var _actual_positions : Array[Vector3] = []


func init(square_positions: Array[Vector3], width: float = 1.007, height: float = 1.66,height_land : float = 0.356) -> void:
	_width_cases      = width
	_height_cases     = height
	_height_land      = height_land
	_actual_positions = square_positions
	print("PropertyHighlighter init: ", _actual_positions.size(), " positions")


func highlight_property(property_id: int, owner_client_id: int, nb_houses: int = 0) -> void:
	if property_id < 0 or property_id >= _actual_positions.size() or property_id % 10 == 0:
		push_warning("highlight_property: property_id %d invalide, size=%d" % [property_id, _actual_positions.size()])
		return

	# On garde le label si déjà existant pour pouvoir le rafraîchir,
	# mais on retire l'ancien quad pour pouvoir le redessiner proprement.
	_clear_quad_only(property_id)
	_create_or_update_label(property_id, owner_client_id, nb_houses)

	var color : Color   = _get_player_color(owner_client_id)
	var pos   : Vector3 = _actual_positions[property_id]
	var side  : int     = _get_side(property_id)

	print("Quad pour case %d → pos=%s" % [property_id, pos])

	var mi   := MeshInstance3D.new()
	var mesh := PlaneMesh.new()

	# Identifier si la case est spéciale (Gares et Compagnies)
	var is_special = property_id in [5, 12, 15, 25, 28, 35]

	# Dimensions et décalages
	var current_height = _height_cases if is_special else (_height_cases - _height_land)
	var offset_h = _height_cases if is_special else (_height_cases + _height_land)

	# Définir la taille du mesh (side % 2 == 0 correspond à side 0 ou 2)
	if side % 2 == 0:
		mesh.size = Vector2(_width_cases, current_height)
	else:
		mesh.size = Vector2(current_height, _width_cases)

	# Position
	var w_half = _width_cases / 2.0
	var h_half = offset_h / 2.0

	# Appliquer les modifications de position
	match side:
		0:
			pos.x += w_half
			pos.z += h_half
		1:
			pos.x -= h_half
			pos.z += w_half
		2:
			pos.x -= w_half
			pos.z -= h_half
		3:
			pos.x += h_half
			pos.z -= w_half

	mi.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color     = Color(color.r, color.g, color.b, 0.0)
	mat.transparency     = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode     = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode        = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat

	# top_level = true : ignore les transforms du parent -> position absolue garantie
	mi.top_level = true
	add_child(mi)
	mi.global_position = pos + Vector3(0, quad_height_offset, 0)
	print("Quad global_position après set = ", mi.global_position)
	_quads[property_id] = mi

	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", color.a, fade_duration)

func clear_property(property_id: int) -> void:
	# Retire à la fois le quad ET le label
	_clear_quad_only(property_id)
	if _labels.has(property_id):
		var lbl = _labels[property_id]
		if is_instance_valid(lbl):
			lbl.queue_free()
		_labels.erase(property_id)

# Retire seulement le quad de surbrillance (pas le label) — utilisé en interne
# quand on rafraîchit une case déjà highlightée.
func _clear_quad_only(property_id: int) -> void:
	if not _quads.has(property_id):
		return
	var mi = _quads[property_id]
	if not is_instance_valid(mi):
		_quads.erase(property_id)
		return
	if is_instance_valid(mi):
		mi.queue_free()
	_quads.erase(property_id)

func clear_all() -> void:
	for pid in _quads.keys():
		clear_property(pid)

# ── Flash temporaire d'une case (destination du pion) ────────────────────────
## Illumine sq_id avec player_color pendant `duration` secondes, puis s'efface.
## Respecte le highlight permanent : restaure l'alpha d'origine après le flash.
## Les coins (sq_id % 10 == 0) sont ignorés.
func flash_square_temp(sq_id: int, player_color: Color, duration: float = 1.2) -> void:
	if sq_id < 0 or sq_id >= _actual_positions.size() or sq_id % 10 == 0:
		return
	# Annule un flash en cours pour la même case
	if _flash_quads.has(sq_id) and is_instance_valid(_flash_quads[sq_id]):
		_flash_quads[sq_id].queue_free()

	var pos  : Vector3 = _actual_positions[sq_id]
	var side : int     = _get_side(sq_id)

	var is_special    : bool  = sq_id in [5, 12, 15, 25, 28, 35]
	var current_height: float = _height_cases if is_special else (_height_cases - _height_land)
	var offset_h      : float = _height_cases if is_special else (_height_cases + _height_land)

	var mi   := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	if side % 2 == 0:
		mesh.size = Vector2(_width_cases, current_height)
	else:
		mesh.size = Vector2(current_height, _width_cases)

	var w_half : float = _width_cases / 2.0
	var h_half : float = offset_h / 2.0
	match side:
		0: pos.x += w_half; pos.z += h_half
		1: pos.x -= h_half; pos.z += w_half
		2: pos.x -= w_half; pos.z -= h_half
		3: pos.x += h_half; pos.z -= w_half

	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color     = Color(player_color.r, player_color.g, player_color.b, 0.85)
	mat.transparency     = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode     = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode        = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.top_level         = true
	add_child(mi)
	mi.global_position   = pos + Vector3(0, quad_height_offset + 0.01, 0)
	_flash_quads[sq_id]  = mi

	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(mat, "albedo_color:a", 0.0, duration)
	await tw.finished
	if is_instance_valid(mi):
		mi.queue_free()
	_flash_quads.erase(sq_id)

func update_owner(property_id: int, new_owner_client_id: int) -> void:
	highlight_property(property_id, new_owner_client_id)


# Crée ou met à jour la pancarte "LOYER Mxxx" au-dessus de la case.
# Structure : Node3D container -> Sprite3D (panneau coloré arrondi) + Label3D (texte blanc).
func _create_or_update_label(property_id: int, owner_client_id: int, nb_houses: int) -> void:
	var container : Node3D = null
	var sprite    : Sprite3D = null
	var label     : Label3D = null

	if _labels.has(property_id) and is_instance_valid(_labels[property_id]):
		container = _labels[property_id]
		sprite    = container.get_node_or_null("Bg") as Sprite3D
		label     = container.get_node_or_null("Text") as Label3D
	else:
		container = Node3D.new()
		container.top_level = true
		add_child(container)

		sprite = Sprite3D.new()
		sprite.name          = "Bg"
		sprite.billboard     = BaseMaterial3D.BILLBOARD_DISABLED   # orientation fixe (plus de billboard)
		sprite.no_depth_test = false
		sprite.fixed_size    = false                                # taille en world units
		sprite.double_sided  = true                                 # visible de derrière
		container.add_child(sprite)

		label = Label3D.new()
		label.name                 = "Text"
		label.billboard            = BaseMaterial3D.BILLBOARD_DISABLED
		label.no_depth_test        = false
		label.fixed_size           = false
		label.double_sided         = true
		label.font_size            = panel_font_size
		label.outline_size         = 4
		label.outline_modulate     = Color(0, 0, 0, 0.95)
		label.modulate             = Color.WHITE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position             = Vector3(0, 0, 0.01)   # juste devant le sprite
		container.add_child(label)

		_labels[property_id] = container

	# Largeur du panneau dans le monde = _width_cases
	# (pixel_size convertit pixels d'image → world units)
	var pixel_world : float = _width_cases / float(TEX_W)
	sprite.pixel_size = pixel_world
	label.pixel_size  = pixel_world

	# Calcul du loyer (dice_total=7 = moyenne pour les compagnies)
	var data = GameData.PROPERTIES.get(property_id, {})
	var prop_type : String = data.get("type", "")
	var rent : int = MonopolyLogic.get_rent(property_id, nb_houses, 7, owner_client_id)
	var rent_text : String
	match prop_type:
		"utility":
			var nb_util = MonopolyLogic.count_owned_type(owner_client_id, "utility")
			var mult : int = 10 if nb_util >= 2 else 4
			rent_text = "LOYER ×%d (dés)" % mult
		_:
			rent_text = "LOYER %d M" % rent

	label.text         = rent_text
	sprite.texture     = _get_panel_texture(_get_label_color(owner_client_id))

	# Position : centre de la case (déjà gère le décalage gauche/droite/haut/bas
	# selon le côté du plateau) + élévation verticale.
	# Rotation : panneau orienté vers l'extérieur du plateau, donc visible
	# depuis la pawn-cam qui regarde le centre du plateau.
	var side : int = _get_side(property_id)
	container.global_position = _case_center(property_id)
	container.rotation        = Vector3(0, _panel_rotation_y(side), 0)


# ─────────────────── Génération de la texture pancarte ───────────────────
# Cache par couleur pour éviter de regénérer 22 fois la même image.
func _get_panel_texture(color: Color) -> ImageTexture:
	var key : String = "%.2f_%.2f_%.2f" % [color.r, color.g, color.b]
	if _panel_tex_cache.has(key):
		return _panel_tex_cache[key]
	var tex : ImageTexture = _make_rounded_panel_texture(color)
	_panel_tex_cache[key] = tex
	return tex


# Dessine une pancarte type "panneau de signalisation" : rectangle arrondi
# coloré en haut, queue triangulaire en bas pointant vers la case.
# Layout vertical (avec top_pad = tail_h pour que le centre du panneau
# coïncide avec le centre de la texture → label centré sans offset) :
#   y =    0 ..  top_pad   →  transparent (padding haut)
#   y =  top_pad .. top_pad+panel_h  →  rectangle arrondi
#   y =  top_pad+panel_h .. h  →  queue triangulaire pointant vers le bas
func _make_rounded_panel_texture(color: Color) -> ImageTexture:
	var w        : int = TEX_W
	var top_pad  : int = 30
	var tail_h   : int = 30
	var panel_h  : int = TEX_H - top_pad - tail_h     # 80 par défaut
	var h        : int = TEX_H
	var r        : int = 16
	var border   : int = 3
	var black    : Color = Color(0, 0, 0, 0.95)

	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# ── Pancarte (rectangle arrondi) ──
	# 1) Bord noir : rounded rect plein
	for py in range(panel_h):
		for px in range(w):
			if _in_rounded_rect(px, py, w, panel_h, r):
				img.set_pixel(px, top_pad + py, black)
	# 2) Intérieur coloré : rounded rect plus petit, décalé de la largeur du bord
	for py in range(border, panel_h - border):
		for px in range(border, w - border):
			if _in_rounded_rect(px - border, py - border, w - 2 * border, panel_h - 2 * border, max(r - border, 1)):
				img.set_pixel(px, top_pad + py, color)

	return ImageTexture.create_from_image(img)


# Rotation Y (en radians) pour orienter le panneau vers l'extérieur du
# plateau (la direction depuis laquelle la pawn-cam regarde la case).
# Le sprite par défaut a sa face visible vers +Z (Sprite3D non billboarded).
#   side 0 (cases 0-10, outward = +Z) : pas de rotation
#   side 1 (cases 11-19, outward = -X) : -90° autour de Y
#   side 2 (cases 20-30, outward = -Z) : 180° autour de Y
#   side 3 (cases 31-39, outward = +X) : +90° autour de Y
func _panel_rotation_y(side: int) -> float:
	match side:
		0: return 0.0
		1: return -PI / 2.0
		2: return PI
		3: return PI / 2.0
	return 0.0


# Test "le pixel (x,y) est-il dans un rounded rect [w,h] de rayon r ?"
func _in_rounded_rect(px: int, py: int, w: int, h: int, r: int) -> bool:
	if px < 0 or px >= w or py < 0 or py >= h:
		return false
	var in_x_corner : bool = px < r or px >= w - r
	var in_top      : bool = py < r # On n'arrondit que le haut
	if not (in_x_corner and in_top):
		return true   # Zone rectangulaire (inclut tout le bas)
	# Zone des coins du haut → distance au centre du coin
	var cx : int = r if px < r else (w - r - 1)
	var cy : int = r
	var dx : float = float(px - cx)
	var dy : float = float(py - cy)
	return sqrt(dx * dx + dy * dy) <= float(r)


# Calcule le centre de la case (à plat sur le plateau), en partant du marqueur
# qui est à un coin et en appliquant le décalage selon le côté.
func _case_center(property_id: int) -> Vector3:
	var pos  : Vector3 = _actual_positions[property_id]
	var w_half : float = _width_cases / 2.0
	
	match _get_side(property_id):
		0:
			pos.x += w_half
		1:
			pos.z += w_half
		2:
			pos.x -= w_half
		3:
			pos.z -= w_half
			
	# On élève la position au-dessus de la case
	pos.y += label_height_offset / 2
	
	return pos


# Met à jour seulement le texte du label (pas le quad coloré) — utilisé
# quand on construit des maisons : le loyer change mais l'highlight existe déjà.
func update_label(property_id: int, owner_client_id: int, nb_houses: int) -> void:
	if not _labels.has(property_id):
		return
	_create_or_update_label(property_id, owner_client_id, nb_houses)


# Permet de rafraîchir tous les labels (utile quand un joueur achète une
# nouvelle gare/compagnie : le loyer des autres gares/compagnies change).
func refresh_all_labels() -> void:
	for pid in _labels.keys():
		var owner = Global.proprietes_joueurs.get(pid, -1)
		if owner == -1:
			continue
		var nb_houses = Global.maisons_proprietes.get(pid, 0)
		_create_or_update_label(pid, owner, nb_houses)


func _get_label_color(client_id: int) -> Color:
	var idx : int = Global.player_color_index.get(client_id, 0)
	return PLAYER_LABEL_COLORS[idx % PLAYER_LABEL_COLORS.size()]


func _get_player_color(client_id: int) -> Color:
	var idx : int = Global.player_color_index.get(client_id, 0)
	return PLAYER_COLORS[idx % PLAYER_COLORS.size()]

func _get_side(sq: int) -> int:
	if sq < 10: return 0
	if sq < 20: return 1
	if sq < 30: return 2
	return 3
