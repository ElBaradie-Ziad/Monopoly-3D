# EndGameScreen.gd
# Écran de fin de partie "Banquet de la Victoire".
# Instancié et ajouté dynamiquement par GameScene._on_jeu_termine().

extends CanvasLayer

# ── Données injectées par GameScene ──────────────────────────────────────────
var winner_id  : int   = -1
var classement : Array = []
var scene_ref  : Node  = null

# ── Constantes visuelles ──────────────────────────────────────────────────────
const BILL_COLORS : Array = [
	Color(0.13, 0.60, 0.20),
	Color(0.85, 0.70, 0.10),
	Color(0.20, 0.50, 0.80),
]
const BILL_COUNT   : int = 40
const FONT_TITLE   : int = 34
const FONT_SUB     : int = 22
const FONT_BODY    : int = 19
const FONT_SMALL   : int = 15

# ── Assets UI ─────────────────────────────────────────────────────────────────
const PATH_PANEL   : String = "res://design_raw/ui_ux/PopUp/Construction_Maison/fond achat.png"
const PATH_BTN     : String = "res://design_raw/ui_ux/login_screen/btn.png"
const PATH_BTN_PRE : String = "res://design_raw/ui_ux/login_screen/btn_press.png"

# ── Couleurs et labels des positions (sans emoji) ─────────────────────────────
const RANK_LABELS  : Array[String] = ["1.", "2.", "3.", "4."]
const RANK_COLORS  : Array         = [
	Color(1.00, 0.82, 0.10),   # or    — 1er
	Color(0.75, 0.75, 0.78),   # argent — 2e
	Color(0.80, 0.50, 0.20),   # bronze — 3e
	Color(0.55, 0.55, 0.55),   # gris   — 4e
]

const LOSER_MESSAGES : Array = [
	"Ne vous inquiétez pas, le Parking Gratuit reste ouvert... pour pleurer.",
	"Consolation : vous avez enrichi quelqu'un. C'est du bénévolat fiscal.",
	"La prochaine fois, achetez au moins une gare. Une seule.",
	"Statistiquement, vous avez nourri l'économie mondiale. Merci.",
	"Votre patrimoine immobilier : zéro. Votre expérience : précieuse.",
]

var _overlay   : ColorRect
var _container : Control

# ═════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	layer = 20

	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	var fade := _overlay.create_tween()
	fade.tween_property(_overlay, "color:a", 0.82, 0.9).set_trans(Tween.TRANS_QUAD)
	await fade.finished

	_spawn_bill_rain()

	_container = Control.new()
	_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_container.custom_minimum_size = Vector2(780, 650)   # hauteur optimisée
	_container.offset_left = -390.0
	_container.offset_right = 390.0
	_container.offset_top = -240.0      # ← remonté pour mieux centrer
	_container.offset_bottom = 340.0
	_container.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_container.modulate = Color(1, 1, 1, 0.0)
	add_child(_container)

	_build_ui()

	var panel_fade := _container.create_tween()
	panel_fade.tween_property(_container, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_QUAD)

func _build_ui() -> void:
	# ── Fond texturé ──────────────────────────────────────────────────────────
	var bg_tex := TextureRect.new()
	bg_tex.texture = load(PATH_PANEL)
	bg_tex.stretch_mode = TextureRect.STRETCH_SCALE
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_container.add_child(bg_tex)

	# ScrollContainer
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 20.0
	scroll.offset_right = -20.0
	scroll.offset_top = 16.0
	scroll.offset_bottom = -16.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_container.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)   # un peu plus d'espace
	scroll.add_child(vbox)

	# ── Titre ─────────────────────────────────────────────────────────────────
	var title_spacer := Control.new()
	title_spacer.custom_minimum_size = Vector2(0, 150)
	vbox.add_child(title_spacer)
	
	var winner_name : String = _get_username(winner_id)
	var victory_margin : int = _compute_victory_margin()
	var title_text : String
	var title_color : Color
	if victory_margin > 1500:
		title_text = "NOUVEAU MAITRE DU MONDE"
		title_color = Color(1.0, 0.82, 0.1)
	elif victory_margin > 500:
		title_text = "TYRAN DE LA RUE DE LA PAIX"
		title_color = Color(1.0, 0.75, 0.15)
	else:
		title_text = "VICTOIRE SUR LE FIL !"
		title_color = Color(0.6, 0.95, 0.4)

	vbox.add_child(_make_label(title_text, FONT_TITLE, title_color, true))
	vbox.add_child(_make_label(winner_name + " remporte la partie", FONT_SUB, Color(1, 1, 1), false))
	vbox.add_child(_make_separator())

	# ── Classement (sans colonne Argent) ──────────────────────────────────────
	vbox.add_child(_make_label("CLASSEMENT FINAL", FONT_BODY, Color(1.0, 0.82, 0.1), true))
	
	var stats_grid := GridContainer.new()
	stats_grid.columns = 3                                      # ← 3 colonnes seulement
	stats_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_grid.add_theme_constant_override("h_separation", 20)
	stats_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(stats_grid)

	# En-têtes (sans "Argent")
	for header : String in ["#", "Joueur", "Valeur nette"]:
		stats_grid.add_child(_make_label(header, FONT_SMALL, Color(0.8, 0.8, 0.8), true))

	# Lignes du classement
	for i in range(classement.size()):
		var entry : Dictionary = classement[i]
		var pid : int = int(entry.get("clientID", -1))
		var name_str : String = _get_username(pid)
		var worth_str : String = str(int(entry.get("netWorth", 0))) + " M"

		var name_color : Color = Color(1.0, 0.82, 0.1) if pid == winner_id else Color(0.85, 0.85, 0.85)
		var rank_color : Color = RANK_COLORS[i] if i < RANK_COLORS.size() else Color(0.55, 0.55, 0.55)
		var rank_lbl : String = RANK_LABELS[i] if i < RANK_LABELS.size() else str(i + 1) + "."

		stats_grid.add_child(_make_label(rank_lbl, FONT_BODY, rank_color, true))
		stats_grid.add_child(_make_label(name_str, FONT_BODY, name_color, false))
		stats_grid.add_child(_make_label(worth_str, FONT_BODY, name_color, false))   # seulement Valeur nette

	vbox.add_child(_make_separator())

	if classement.size() > 1:
		var loser_msg : String = LOSER_MESSAGES[randi() % LOSER_MESSAGES.size()]
		vbox.add_child(_make_label(loser_msg, FONT_SMALL, Color(0.55, 0.55, 0.55), false))
		vbox.add_child(_make_separator())

		# ── Bouton texturé (corrigé : plus jamais rouge par défaut) ────────────────────────────────────────────────────────
	var btn := Button.new()
	btn.text = "Retour au menu principal"
	btn.custom_minimum_size = Vector2(274, 100)
	btn.add_theme_font_size_override("font_size", FONT_BODY)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_on_return_pressed)
	
	# IMPORTANT : supprime le style Godot par défaut (focus + rouge)
	btn.focus_mode = Control.FOCUS_NONE
	
	# Styles custom avec tes textures
	var sbox_normal := StyleBoxTexture.new()
	sbox_normal.texture = load(PATH_BTN)
	sbox_normal.set_texture_margin_all(8.0)
	
	var sbox_pressed := StyleBoxTexture.new()
	sbox_pressed.texture = load(PATH_BTN_PRE)
	sbox_pressed.set_texture_margin_all(8.0)	
	var sbox_hover := StyleBoxTexture.new()
	sbox_hover.texture = load(PATH_BTN)
	sbox_hover.set_texture_margin_all(8.0)
	sbox_hover.modulate_color = Color(1.15, 1.15, 1.15, 1.0)
	
	btn.add_theme_stylebox_override("normal", sbox_normal)
	btn.add_theme_stylebox_override("pressed", sbox_pressed)
	btn.add_theme_stylebox_override("hover", sbox_hover)
	btn.add_theme_stylebox_override("focus", sbox_normal)   # même style que normal
	
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.85, 0.85, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	
	# === SPACER pour pousser le bouton en bas sans espace vide excessif ===
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	vbox.add_child(btn)
# ═════════════════════════════════════════════════════════════════════════════
func _spawn_bill_rain() -> void:
	var screen : Rect2 = get_viewport().get_visible_rect()
	for i in range(BILL_COUNT):
		var bill     := ColorRect.new()
		bill.color    = BILL_COLORS[i % BILL_COLORS.size()]
		bill.color.a  = 0.85
		bill.size     = Vector2(randf_range(28.0, 55.0), randf_range(14.0, 24.0))
		var start_x  : float = randf_range(0.0, screen.size.x)
		bill.position = Vector2(start_x, -40.0)
		add_child(bill)

		var delay   : float = randf_range(0.0, 2.5)
		var dur     : float = randf_range(3.0, 6.5)
		var end_y   : float = screen.size.y + 60.0
		var rot_end : float = randf_range(-PI * 4.0, PI * 4.0)

		# set_parallel + set_delay : chaque propriété démarre après `delay` secondes,
		# toutes en parallèle. (tween_interval + set_parallel annulait le délai.)
		var tw : Tween = bill.create_tween()
		tw.set_parallel(true)
		tw.tween_property(bill, "position:y", end_y,   dur) \
			.set_delay(delay).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(bill, "rotation",   rot_end, dur) \
			.set_delay(delay).set_trans(Tween.TRANS_SINE)
		tw.tween_property(bill, "position:x",
			start_x + randf_range(-120.0, 120.0), dur) \
			.set_delay(delay).set_trans(Tween.TRANS_SINE)


# ═════════════════════════════════════════════════════════════════════════════
func _make_label(text: String, font_size: int, color: Color, _bold: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text                  = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return lbl

func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(1.0, 0.82, 0.1, 0.35))
	sep.add_theme_constant_override("separation", 6)
	return sep

# ═════════════════════════════════════════════════════════════════════════════
func _get_username(client_id: int) -> String:
	# 1. Classement reçu du serveur (source la plus fiable)
	for entry in classement:
		if entry is Dictionary and int(entry.get("clientID", -1)) == client_id:
			var uname : String = str(entry.get("username", ""))
			if uname != "":
				return uname
	# 2. Lobby local — essaie "username" puis "pseudo"
	for p : Dictionary in Global.lobby_players:
		if int(p.get("clientID", -1)) == client_id:
			var uname : String = str(p.get("username", p.get("pseudo", "")))
			if uname != "":
				return uname
	# 3. Dernier recours
	return "Joueur " + str(client_id)

func _compute_victory_margin() -> int:
	if classement.size() < 2:
		return 9999
	var e0 : Dictionary = classement[0]
	var e1 : Dictionary = classement[1]
	var first_worth  : int = int(e0.get("netWorth", 0))
	var second_worth : int = int(e1.get("netWorth", 0))
	return first_worth - second_worth

func _on_return_pressed() -> void:
	var paquet = {
		"mainID": 5,
		"subID": 1,
		"clientID": Global.my_client_id,
		"data": { "matchID": Global.current_match_id }
	}
	Reseau.send_data(paquet)
	Global.reset_stats()
	get_tree().change_scene_to_file("res://main_menu_v2.tscn")
