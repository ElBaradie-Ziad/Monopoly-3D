# GameUI.gd
extends CanvasLayer

signal roll_dice_pressed
signal end_turn_pressed
signal buy_decision_received(accepted: bool)
signal jail_pay_pressed
signal jail_card_pressed
signal popup_finished

# ── Timer de tour (15 s → action par défaut) ─────────────────────────────────
const TurnTimerScript = preload("res://scripts/ui/TurnTimer.gd")
var _turn_timer : Control = null  # instancié dans _ready()

# Références aux popups
@onready var popups = {
	"achat": $Control/BuyPropertyPopup,
	"prison": $Control/ActionsPrison,
	"chance": $Control/ChanceCardPopup,
	"community": $Control/CommunityCardPopup,
	"taxe_impot": $Control/TaxeImpot,
	"taxe_luxe": $Control/TaxeLuxe,
	"achat_maison" : $Control/AchatMaison
}

# Références aux conteneurs de boutons
@onready var btn_containers = {
	"roll": $Control/HUD/BottomPanel/Marge/BoutonsBasEcran/ROLLDICE,
	"end": $Control/HUD/BottomPanel/Marge/BoutonsBasEcran/ENDTURN,
	"jail_roll": $Control/ActionsPrison/MarginContainer/VBoxContainer/VBoxContainer/rolldice,
	"jail_pay": $Control/ActionsPrison/MarginContainer/VBoxContainer/VBoxContainer/pay,
	"jail_card": $Control/ActionsPrison/MarginContainer/VBoxContainer/VBoxContainer/card,
	"maison_up" : $Control/AchatMaison/MarginContainer/VBoxContainer/HouseSelector/PlusControl/Plus,
	"maison_down" :  $Control/AchatMaison/MarginContainer/VBoxContainer/HouseSelector/MinusControl/Minus,
	"maison_buy" : $Control/AchatMaison/MarginContainer/VBoxContainer/VBoxContainer/AcheterControl/Acheter,
	"maison_pass" :  $Control/AchatMaison/MarginContainer/VBoxContainer/VBoxContainer/PasserControl/Button
	
}



@onready var label_turn = $Control/HUD/Text_change_turn
@onready var dice_ui = $Control/DiceManager
@onready var prison_turns_label = $Control/ActionsPrison/MarginContainer/VBoxContainer/turns

@onready var label_nom_maison = $Control/AchatMaison/MarginContainer/VBoxContainer/Header/Nom
@onready var nb_maisons_current = $Control/AchatMaison/MarginContainer/VBoxContainer/Owner/owner
@onready var nb_maisons_to_buy = $Control/AchatMaison/MarginContainer/VBoxContainer/HouseSelector/HouseNumber/Label
@onready var prix_maisons_to_buy = $Control/AchatMaison/MarginContainer/VBoxContainer/PriceBlock/BuyPrice
var money_labels : Dictionary = {}



func _ready():
	# ── Création et positionnement du cercle timer ────────────────────────────
	_turn_timer = TurnTimerScript.new()
	# Ancré au bas-centre, au-dessus de la barre de boutons
	_turn_timer.anchor_left   = 0.5
	_turn_timer.anchor_right  = 0.5
	_turn_timer.anchor_top    = 1.0
	_turn_timer.anchor_bottom = 1.0
	_turn_timer.offset_left   = -34.0   # moitié de la largeur (~68 px)
	_turn_timer.offset_right  =  34.0
	_turn_timer.offset_top    = -72.0   # juste SOUS les boutons bas
	_turn_timer.offset_bottom = -4.0
	_turn_timer.z_index       = 10      # toujours devant le HUD
	$Control.add_child(_turn_timer)

	# 1. Connexion des boutons du HUD et de la Prison
	# → chaque bouton stoppe le timer AVANT d'émettre son signal
	btn_containers.roll.get_node("BoutonRollDice").pressed.connect(func():
		_stop_timer()
		roll_dice_pressed.emit())
	btn_containers.end.get_node("BoutonEndTurn").pressed.connect(func():
		_stop_timer()
		end_turn_pressed.emit())
	btn_containers.jail_roll.get_node("TextureButton").pressed.connect(func():
		_stop_timer()
		roll_dice_pressed.emit())
	btn_containers.jail_pay.get_node("TextureButton").pressed.connect(func():
		_stop_timer()
		jail_pay_pressed.emit())
	btn_containers.jail_card.get_node("TextureButton").pressed.connect(func():
		_stop_timer()
		jail_card_pressed.emit())
	btn_containers.maison_up.pressed.connect(_on_maison_up)
	btn_containers.maison_down.pressed.connect(_on_maison_down)
	btn_containers.maison_buy.pressed.connect(func():
		_stop_timer()
		_on_maison_buy())
	btn_containers.maison_pass.pressed.connect(func():
		_stop_timer()
		popups.achat_maison.hide())

	# 2. Connexion du popup d'achat (achat.gd)
	# On branche uniquement le signal 'choice_made' qui existe dans ton script
	# → stoppe le timer dès que le joueur a choisi (acheté OU refusé)
	popups.achat.choice_made.connect(func(accepted: bool):
		_stop_timer()
		_on_buy_choice_received(accepted))

# Fonction de relais pour la GameScene
func _on_buy_choice_received(accepted: bool):
	buy_decision_received.emit(accepted)

# ── Helpers timer ─────────────────────────────────────────────────────────────

## Démarre le compte à rebours avec un callback "action par défaut".
func _start_timer(default_callback: Callable) -> void:
	if _turn_timer:
		_turn_timer.start(default_callback)

## Stoppe le timer (joueur a agi à temps).
func _stop_timer() -> void:
	if _turn_timer:
		_turn_timer.stop()

# --- RESTE DU CODE (SANS CHANGEMENT) ---

# GameUI.gd

var player_money_values : Dictionary = {} # clientID (int) -> montant (int)
var _is_updating : bool = false

func setup_money_labels(players: Array, labels: Array):
	money_labels.clear()
	player_money_values.clear()
	for i in range(players.size()):
		var id = int(players[i].get("clientID", -1))
		if id != -1 and i < labels.size():
			money_labels[id] = labels[i]
			# On initialise la valeur réelle au départ
			player_money_values[id] = Global.argent_depart 
			labels[i].text = str(Global.argent_depart) + " M"

func update_money(client_id: int, delta: int):
	# 1. ATTENTE : Si déjà en cours, on attend la frame suivante
	while _is_updating:
		await get_tree().process_frame
	
	# 2. VERROUILLAGE
	_is_updating = true
	
	var id_key = int(client_id)
	if money_labels.has(id_key):
		var old_value = player_money_values[id_key]
		var new_value = old_value + delta
		
		# On met à jour la valeur "source de vérité" immédiatement
		player_money_values[id_key] = new_value
		
		# On attend que l'animation soit physiquement terminée
		await UiAnimationManager.animate_label(money_labels[id_key], old_value, new_value)
	
	# 3. LIBÉRATION
	_is_updating = false


func has_negative_balance() -> int:
	for balance in player_money_values.values():
		if balance < 0:
			return 1
	return 0

func update_prison_ui(tours: int, has_card: bool):
	prison_turns_label.text = "Tours restants : " + str(tours)
	btn_containers.jail_roll.visible = (tours > 1)
	btn_containers.jail_card.visible = has_card and (tours > 1)
	popups.prison.show()

	# ── Timer prison : action par défaut = lancer les dés (ou payer si dernier tour) ──
	if tours > 1:
		_start_timer(func():
			_stop_timer()
			roll_dice_pressed.emit())
	else:
		# Dernier tour en prison : payer obligatoire
		_start_timer(func():
			_stop_timer()
			jail_pay_pressed.emit())

func text_tour_change(text: String):
	label_turn.text = text
	label_turn.show()
	await get_tree().create_timer(2.0).timeout
	label_turn.hide()

# Affiche un aperçu du déplacement : "+3 cases ↞ vers la gauche → Rue de Vaugirard".
# Fire-and-forget : ne pas await côté appelant pour laisser le déplacement
# s'animer en parallèle de l'affichage.
func show_move_preview(steps: int, dest_name: String, direction: String = "") -> void:
	if label_turn == null:
		return
	var sign : String = "+" if steps >= 0 else ""
	var plural : String = "s" if abs(steps) > 1 else ""
	if direction == "":
		label_turn.text = "%s%d case%s → %s" % [sign, steps, plural, dest_name]
	else:
		label_turn.text = "%s%d case%s   %s   →  %s" % [sign, steps, plural, direction, dest_name]
	label_turn.show()
	await get_tree().create_timer(2.5).timeout
	label_turn.hide()

func set_controls(can_roll: bool, can_end: bool):
	btn_containers.roll.visible = can_roll
	btn_containers.end.visible  = can_end

	# ── Timer : démarre si un bouton devient actif, s'arrête sinon ──────────
	if can_roll:
		# Action par défaut : lancer les dés automatiquement
		_start_timer(func(): roll_dice_pressed.emit())
	elif can_end:
		# Action par défaut : fin de tour automatique
		_start_timer(func(): end_turn_pressed.emit())
	else:
		_stop_timer()

func show_popup(type: String, data = null,current_player_id = -1):
	if not popups.has(type):
		return

	if type == "achat":
		popups.achat.show_property(data)
			
	elif type  == "chance":
		popups[type].show_card(data)
	elif type == "community":
		SoundManager.play_coffre()
		popups[type].show_card(data)


	popups[type].show()

	# ── Timer pour le popup d'achat uniquement ───────────────────────────────
	if type == "achat":
		# Action par défaut : refuser l'achat (passer)
		_start_timer(func():
			if popups.achat.visible:
				popups.achat._on_btn_deny_pressed())

	# LOGIQUE AUTO-HIDE :
	# Si c'est une taxe ou une carte, on attend 4s puis on cache
	if type != "achat" and type != "prison":
		await get_tree().create_timer(4.0).timeout
		popups[type].hide()
		popup_finished.emit() # On prévient que le temps est écoulé

func hide_all_popups():
	_stop_timer()
	for p in popups.values():
		p.hide()
		
var _maison_property_id: int = -1
var _maison_compteur: int = 0
var _maisons_actuelles: int = 0
var _current_prop_house_price = 0


	


func show_popup_maison(prop_id: int):
	_maison_property_id = prop_id
	_maisons_actuelles = Global.maisons_proprietes.get(prop_id, 0)
	if _maisons_actuelles >= 5: #fix pour éviter de mettre le popup si on ne peut plus acheter de maisons du tout (hotel déjà présent)
		return
	_maison_compteur = 0
	var prop = GameData.PROPERTIES.get(prop_id, {})
	label_nom_maison.text = prop.get("name", "???")
	_current_prop_house_price = prop.get("house_cost",0)
	_refresh_maison_ui()
	popups.achat_maison.show()

	# ── Timer maison : action par défaut = passer (ne rien acheter) ──────────
	_start_timer(func():
		if popups.achat_maison.visible:
			popups.achat_maison.hide())

func _refresh_maison_ui():
	nb_maisons_current.text = str(_maisons_actuelles) + " → " + str(_maisons_actuelles + _maison_compteur)
	nb_maisons_to_buy.text= str(_maison_compteur)
	prix_maisons_to_buy.text = "Prix à Payer :" + str(_maison_compteur*_current_prop_house_price) +"M" 
	btn_containers.maison_up.disabled = (_maisons_actuelles + _maison_compteur >= 5)
	btn_containers.maison_down.disabled = (_maison_compteur <= 0)
	btn_containers.maison_buy.disabled = (_maison_compteur <= 0)

func _on_maison_up():
	if _maisons_actuelles + _maison_compteur < 5:
		_maison_compteur += 1
		_refresh_maison_ui()

func _on_maison_down():
	if _maison_compteur > 0:
		_maison_compteur -= 1
		_refresh_maison_ui()

func _on_maison_buy():
	if _maison_compteur <= 0:
		return

	ReseauManager.build_house(_maison_property_id, _maison_compteur+_maisons_actuelles)
	popups.achat_maison.hide()
