extends Control

# --- Chargement des icônes ---
const ICON_CLASSE_1 = preload("res://design_raw/ui_ux/voleur_classe.png")
const ICON_CLASSE_2 = preload("res://design_raw/ui_ux/double_classe.png")
const ICON_CLASSE_3 = preload("res://design_raw/ui_ux/case_depart_classe.png")

const PLAYER_COLORS : Array = [
	Color(0.9, 0.15, 0.15, 1), # Rouge
	Color(0.15, 0.35, 0.9,  1), # Bleu
	Color(0.15, 0.75, 0.25, 1), # Vert
	Color(0.95, 0.80, 0.10, 1), # Jaune
]

# --- Références UI ---
@onready var player1_name = $LeftPanel/Margin/PlayersContainer/Player1/MarginContainer/ElementsPlayer/VBoxContainer/P1_Name
@onready var player2_name = $LeftPanel/Margin/PlayersContainer/Player2/MarginContainer/ElementsPlayer/VBoxContainer/P2_Name
@onready var player3_name = $LeftPanel/Margin/PlayersContainer/Player3/MarginContainer/ElementsPlayer/VBoxContainer/P3_Name
@onready var player4_name = $LeftPanel/Margin/PlayersContainer/Player4/MarginContainer/ElementsPlayer/VBoxContainer/P4_Name

@onready var player1_avatar = $LeftPanel/Margin/PlayersContainer/Player1/MarginContainer/ElementsPlayer/Avatar
@onready var player2_avatar = $LeftPanel/Margin/PlayersContainer/Player2/MarginContainer/ElementsPlayer/Avatar
@onready var player3_avatar = $LeftPanel/Margin/PlayersContainer/Player3/MarginContainer/ElementsPlayer/Avatar
@onready var player4_avatar = $LeftPanel/Margin/PlayersContainer/Player4/MarginContainer/ElementsPlayer/Avatar

@onready var player1_background = $LeftPanel/Margin/PlayersContainer/Player1/ColorBackground
@onready var player2_background = $LeftPanel/Margin/PlayersContainer/Player2/ColorBackground
@onready var player3_background = $LeftPanel/Margin/PlayersContainer/Player3/ColorBackground
@onready var player4_background = $LeftPanel/Margin/PlayersContainer/Player4/ColorBackground

@onready var player1_money = $LeftPanel/Margin/PlayersContainer/Player1/MarginContainer/ElementsPlayer/VBoxContainer/P1_Money
@onready var player2_money = $LeftPanel/Margin/PlayersContainer/Player2/MarginContainer/ElementsPlayer/VBoxContainer/P2_Money
@onready var player3_money = $LeftPanel/Margin/PlayersContainer/Player3/MarginContainer/ElementsPlayer/VBoxContainer/P3_Money
@onready var player4_money = $LeftPanel/Margin/PlayersContainer/Player4/MarginContainer/ElementsPlayer/VBoxContainer/P4_Money

# Listes pour l'itération
var _slot_labels      : Array
var _slot_avatars     : Array
var _slot_backgrounds : Array
var _slot_moneys      : Array
var _slot_patrimoines : Array[Label]  # Label "Net : xxx M" sous chaque argent

func _ready() -> void:
	_slot_labels      = [player1_name,       player2_name,       player3_name,       player4_name      ]
	_slot_avatars     = [player1_avatar,      player2_avatar,     player3_avatar,     player4_avatar    ]
	_slot_backgrounds = [player1_background,  player2_background, player3_background, player4_background]
	_slot_moneys      = [player1_money,       player2_money,      player3_money,      player4_money     ]

	# On commence par tout cacher (au cas où il y a moins de 4 joueurs)
	for slot in _slot_backgrounds:
		slot.get_parent().hide()

	# Icônes carte prison (ajoutées avant la boucle joueurs pour que les VBox soient prêtes)
	_setup_prison_icons()
	# Labels patrimoine (ajoutés sous les labels argent)
	_setup_patrimoine_labels()

	# Initialisation des joueurs présents
	for i in range(Global.lobby_players.size()):
		var player_data = Global.lobby_players[i]
		var c_id = int(player_data["clientID"])
		
		# Afficher le slot
		_slot_backgrounds[i].get_parent().show()
		
		# 1. Texte du pseudo
		_slot_labels[i].text = player_data["username"]
		
		# 2. Couleur du Background
		_slot_backgrounds[i].color = _get_player_color(c_id)
		
		# 3. Configuration et attribution de l'Avatar
		var avatar_node = _slot_avatars[i]
		_setup_avatar_rect(avatar_node)
		_assign_avatar_texture(avatar_node, c_id)

# --- Fonctions Utilitaires ---

func _get_player_color(client_id: int) -> Color:
	var idx : int = Global.player_color_index.get(client_id, 0)
	return PLAYER_COLORS[idx % PLAYER_COLORS.size()]

func _setup_avatar_rect(node: TextureRect) -> void:
	node.custom_minimum_size = Vector2(64, 64)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _assign_avatar_texture(node: TextureRect, client_id: int) -> void:
	if Global.classe1.has(client_id):
		node.texture = ICON_CLASSE_1
	elif Global.classe2.has(client_id):
		node.texture = ICON_CLASSE_2
	elif Global.classe3.has(client_id):
		node.texture = ICON_CLASSE_3
	else:
		node.texture = null
		
		
		
		
		
		
		
		
		
		
		
# ══════════════════════════════════════════════════════════════════
# ── Animation d'élimination HUD ───────────────────────────────────

## Lance l'animation de mort sur le slot HUD du joueur éliminé (fire-and-forget).
## Séquence : flashs rouges → skull "💀 ÉLIMINÉ" → fond noir → fondu sortant → hide.
func play_slot_elimination(client_id: int) -> void:
	# ── Trouver le slot ───────────────────────────────────────────────────────
	var idx := -1
	for i in range(Global.lobby_players.size()):
		if int(Global.lobby_players[i].get("clientID", -1)) == client_id:
			idx = i
			break
	if idx < 0 or idx >= _slot_backgrounds.size():
		return

	var slot      : Control  = _slot_backgrounds[idx].get_parent()   # nœud PlayerX
	var bg        : ColorRect = _slot_backgrounds[idx]
	var money_lbl : Label    = _slot_moneys[idx]
	if not is_instance_valid(slot) or not slot.visible:
		return

	var base_color : Color = bg.color

	# ── 1. Trois flashs rouges rapides ───────────────────────────────────────
	for _i in range(3):
		var tw := bg.create_tween()
		tw.tween_property(bg, "color", Color(0.85, 0.05, 0.05), 0.08)
		tw.tween_property(bg, "color", base_color,               0.13)
		await tw.finished

	# ── 2. Label "💀 ÉLIMINÉ" en fade-in, centré sur le slot ─────────────────
	var skull := Label.new()
	skull.text                = "💀  ÉLIMINÉ"
	skull.add_theme_font_size_override("font_size", 17)
	skull.add_theme_color_override("font_color", Color(1.0, 0.22, 0.22))
	skull.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skull.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	skull.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	skull.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	skull.modulate.a           = 0.0
	slot.add_child(skull)

	# Phase 2 : fond qui noircit + skull qui apparaît + argent qui s'efface
	# (les trois tweens partent en même temps, chacun sur son nœud)
	var tw_bg := bg.create_tween()
	tw_bg.tween_property(bg, "color", Color(0.07, 0.05, 0.05), 0.35)

	var tw_sk := skull.create_tween()
	tw_sk.tween_property(skull, "modulate:a", 1.0, 0.30).set_trans(Tween.TRANS_QUAD)

	var tw_mn := money_lbl.create_tween()
	tw_mn.tween_property(money_lbl, "modulate:a", 0.0, 0.35)

	await tw_sk.finished   # le plus court : ~0.30 s

	# ── 3. Pause lisibilité ───────────────────────────────────────────────────
	await get_tree().create_timer(0.75).timeout

	# ── 4. Fondu sortant du slot entier ──────────────────────────────────────
	var tw_fade := slot.create_tween()
	tw_fade.tween_property(slot, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_QUAD)
	await tw_fade.finished
	# On NE cache PAS le slot (pas de hide()) : dans un VBoxContainer, hide() retire
	# le nœud du layout et les slots en-dessous remontent, volant la couleur du mort.
	# modulate.a = 0 le rend invisible tout en gardant sa place dans le layout.
	money_lbl.modulate.a = 1.0  # reset interne au cas où le slot serait réaffiché


############## LOG CODE########################

@onready var log_list = $"DroitPannel/DroitPannelChild/Historique Action"
var custom_font = load("res://ressource/fonts/Minecraft 2.ttf")

const MAX_SUMMARIES = 8

var current_turn_label : RichTextLabel = null
var current_turn_text : String = ""

# Icônes "carte sortie de prison" par slot joueur (créées dynamiquement)
var _prison_icons : Array[Label] = []

# ══════════════════════════════════════════════════════════════════
# ── Helpers couleur ───────────────────────────────────────────────

func _client_color_hex(client_id: int) -> String:
	if client_id < 0:
		return "ffff00"
	return _get_player_color(client_id).to_html(false)

## Retourne la couleur groupe d'une propriété (brightened pour lisibilité).
func _prop_color_hex(prop_id: int) -> String:
	if prop_id < 0:
		return "e6c300"  # or gold fallback
	var data = GameData.PROPERTIES.get(prop_id, {})
	var col : Color = data.get("color", Color(0.9, 0.76, 0.0))
	col = col.lightened(0.25)
	return col.to_html(false)

# ── Helper : crée et insère une entrée BBCode dans le log ──────────────────
func _add_log_entry(bbcode_text: String) -> RichTextLabel:
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 5)
	margin_container.add_theme_constant_override("margin_right", 5)
	margin_container.add_theme_constant_override("margin_top", 10)
	margin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	if custom_font:
		label.add_theme_font_override("normal_font", custom_font)
		label.add_theme_font_override("bold_font", custom_font)
		label.add_theme_font_size_override("normal_font_size", 17)
	
	label.text = bbcode_text
	margin_container.add_child(label)
	
	# === PARTIE CORRIGÉE ===
	log_list.add_child(margin_container)           # On ajoute d'abord
	
	# On supprime les plus anciens tant qu'on dépasse la limite
	while log_list.get_child_count() > MAX_SUMMARIES:
		var oldest = log_list.get_child(0)
		log_list.remove_child(oldest)
		oldest.queue_free()
	
	return label

# ══════════════════════════════════════════════════════════════════
# ── Icône carte sortie de prison ──────────────────────────────────

## Crée un label "Net : -- M" sous chaque label d'argent dans le VBoxContainer.
func _setup_patrimoine_labels() -> void:
	_slot_patrimoines.clear()
	for i in range(4):
		if i >= _slot_moneys.size():
			break
		var money_lbl : Label = _slot_moneys[i]
		var vbox = money_lbl.get_parent()   # VBoxContainer (Name + Money + [Patrimoine])

		var lbl := Label.new()
		lbl.text = "Net : -- M"
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(lbl)

		_slot_patrimoines.append(lbl)

## Met à jour le label patrimoine du joueur identifié par client_id.
func update_patrimoine(client_id: int, amount: int) -> void:
	var idx : int = -1
	for i in range(Global.lobby_players.size()):
		if int(Global.lobby_players[i].get("clientID", -1)) == client_id:
			idx = i
			break
	if idx >= 0 and idx < _slot_patrimoines.size():
		_slot_patrimoines[idx].text = "Net : %d M" % amount

## Ajoute dynamiquement une petite étiquette "🗝" sous l'avatar de chaque joueur.
## On enveloppe l'Avatar dans un VBoxContainer [Avatar / icône] pour que l'icône
## apparaisse visuellement sous l'image, dans la colonne gauche de ElementsPlayer.
func _setup_prison_icons() -> void:
	_prison_icons.clear()
	for i in range(4):
		if i >= _slot_avatars.size():
			break
		var avatar_node : TextureRect = _slot_avatars[i]
		var hbox = avatar_node.get_parent()   # ElementsPlayer (HBoxContainer)

		# Créer un wrapper vertical [Avatar | icône]
		var wrapper := VBoxContainer.new()
		wrapper.alignment = BoxContainer.ALIGNMENT_CENTER

		# Déplacer l'avatar dans le wrapper
		hbox.remove_child(avatar_node)
		wrapper.add_child(avatar_node)

		# Icône sous l'avatar
		var icon := Label.new()
		icon.text = "🗝  Liberté"
		icon.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		icon.add_theme_font_size_override("font_size", 11)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.hide()
		wrapper.add_child(icon)

		# Réinsérer le wrapper à la place de l'avatar (index 0 dans le HBoxContainer)
		hbox.add_child(wrapper)
		hbox.move_child(wrapper, 0)

		_prison_icons.append(icon)

## Affiche ou cache l'icône pour le joueur donné.
func update_prison_card_icon(client_id: int, has_card: bool) -> void:
	var idx : int = -1
	for i in range(Global.lobby_players.size()):
		if int(Global.lobby_players[i].get("clientID", -1)) == client_id:
			idx = i
			break
	if idx >= 0 and idx < _prison_icons.size():
		_prison_icons[idx].visible = has_card

# ══════════════════════════════════════════════════════════════════
# ── Entrées de log ────────────────────────────────────────────────

## Déplacement / lancer de dés
func start_new_turn_log(player_name: String, roll: int, case_name: String, client_id: int = -1, case_pos: int = -1):
	var name_hex  : String = _client_color_hex(client_id)
	var case_hex  : String = _prop_color_hex(case_pos) if case_pos >= 0 else "00d4ff"
	current_turn_text = "[color=#%s]%s[/color] a fait %d et s'arrête sur [color=#%s]%s[/color]" % [name_hex, player_name, roll, case_hex, case_name]
	current_turn_label = _add_log_entry(current_turn_text)

## Achat de propriété
func log_achat_propriete(player_name: String, prop_name: String, client_id: int = -1, prop_id: int = -1) -> void:
	var name_hex = _client_color_hex(client_id)
	var prop_hex = _prop_color_hex(prop_id)
	_add_log_entry("[color=#%s]%s[/color] achète [color=#%s]%s[/color]" % [name_hex, player_name, prop_hex, prop_name])

## Construction maison / hôtel
func log_construction(player_name: String, prop_name: String, nb_added: int, total: int, client_id: int = -1, prop_id: int = -1) -> void:
	var name_hex = _client_color_hex(client_id)
	var prop_hex = _prop_color_hex(prop_id)
	var batiment : String
	if total >= 5:
		batiment = "un [color=tomato]hôtel[/color]"
	elif nb_added == 1:
		batiment = "1 [color=lime]maison[/color]"
	else:
		batiment = "%d [color=lime]maisons[/color]" % nb_added
	_add_log_entry("[color=#%s]%s[/color] construit %s sur [color=#%s]%s[/color]" % [name_hex, player_name, batiment, prop_hex, prop_name])

## Paiement de loyer
func log_payer_loyer(payer_name: String, owner_name: String, prop_name: String, amount: int, payer_id: int = -1, owner_id: int = -1, prop_id: int = -1) -> void:
	var payer_hex = _client_color_hex(payer_id)
	var owner_hex = _client_color_hex(owner_id)
	var prop_hex  = _prop_color_hex(prop_id)
	_add_log_entry("[color=#%s]%s[/color] paie [color=tomato]%d M[/color] à [color=#%s]%s[/color] — [color=#%s]%s[/color]" % [payer_hex, payer_name, amount, owner_hex, owner_name, prop_hex, prop_name])

## Passage par la case Départ
func log_passe_depart(player_name: String, amount: int, client_id: int = -1) -> void:
	var hex = _client_color_hex(client_id)
	_add_log_entry("[color=#%s]%s[/color] passe par [color=lime]DÉPART[/color]  +[color=lime]%d M[/color]" % [hex, player_name, amount])

## Taxe
func log_taxe(player_name: String, is_income_tax: bool, amount: int, client_id: int = -1) -> void:
	var hex   = _client_color_hex(client_id)
	var label = "Impôts sur le revenu" if is_income_tax else "Taxe de luxe"
	_add_log_entry("[color=#%s]%s[/color] paie [color=tomato]%d M[/color] — [color=tomato]%s[/color]" % [hex, player_name, amount, label])

## Carte Chance / Caisse de communauté
func log_carte(player_name: String, card_text: String, card_type: String, client_id: int = -1) -> void:
	var hex   = _client_color_hex(client_id)
	var tcol  = "lime" if card_type == "positive" else ("tomato" if card_type == "negative" else "cyan")
	_add_log_entry("[color=#%s]%s[/color] : [color=%s]%s[/color]" % [hex, player_name, tcol, card_text])

## Faillite
func log_faillite(player_name: String, client_id: int = -1) -> void:
	var hex = _client_color_hex(client_id)
	_add_log_entry("[color=#%s]%s[/color] [color=tomato]est en faillite ![/color]" % [hex, player_name])

## Effet de classe activé (Voleur, Élite, Départ)
func log_effet_classe(player_name: String, description: String, client_id: int = -1) -> void:
	var hex = _client_color_hex(client_id)
	_add_log_entry("[color=#%s]%s[/color] [color=cyan]%s[/color]" % [hex, player_name, description])

# ── Mise à jour de l'entrée courante ──────────────────────────────────────
func update_turn_log(extra_info: String):
	if current_turn_label:
		current_turn_text += " " + extra_info
		current_turn_label.text = current_turn_text
