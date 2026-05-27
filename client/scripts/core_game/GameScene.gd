extends Node3D

# --- Références UI & plateau ---
@onready var ui = $CanvasLayer
@onready var board = $SandboxBoard
@onready var log = $CanvasLayer/Control/HUD
@onready var labels_argent = [
	$CanvasLayer/Control/HUD/LeftPanel/Margin/PlayersContainer/Player1/MarginContainer/ElementsPlayer/VBoxContainer/P1_Money,
	$CanvasLayer/Control/HUD/LeftPanel/Margin/PlayersContainer/Player2/MarginContainer/ElementsPlayer/VBoxContainer/P2_Money,
	$CanvasLayer/Control/HUD/LeftPanel/Margin/PlayersContainer/Player3/MarginContainer/ElementsPlayer/VBoxContainer/P3_Money,
	$CanvasLayer/Control/HUD/LeftPanel/Margin/PlayersContainer/Player4/MarginContainer/ElementsPlayer/VBoxContainer/P4_Money
]
@onready var tour_label = $CanvasLayer/Control/LabelTours
@onready var player_containers = [
	$CanvasLayer/Control/HUD/LeftPanel/Margin/PlayersContainer/Player1,
	$CanvasLayer/Control/HUD/LeftPanel/Margin/PlayersContainer/Player2,
	$CanvasLayer/Control/HUD/LeftPanel/Margin/PlayersContainer/Player3,
	$CanvasLayer/Control/HUD/LeftPanel/Margin/PlayersContainer/Player4
]



# --- État local du tour ---
var my_turn : bool = false
var current_player_id : int = -1
var des_deja_lances : bool = false     # true = déjà lancé ce tour
var vient_de_sortir_prison : bool = false
var des_en_cours : bool = false        # verrou animation/achat
var _movement_active : bool = false    # true pendant que le pion se déplace physiquement
var pending_prison_clear : bool = false
var doubles_consecutifs : int = 0
var intro_en_cours : bool = true       # true tant que l'animation d'intro n'est pas terminée
@onready var  elimination = 0
func _ready():
	Global.positions_joueurs.clear()
	Global.proprietes_joueurs.clear()
	Global.maisons_proprietes.clear()
	Global.etat_prison.clear()
	Global.cartes_prison.clear()
	Global.classement_final.clear()
	Global.loyer_total_percu.clear()
	Global.nb_passages_prison.clear()
	Global.current_client_id = -1
	current_player_id=-1
	ui.setup_money_labels(Global.lobby_players, labels_argent)
	
	# Connexions UI -> Réseau
	ui.roll_dice_pressed.connect(ReseauManager.roll_dice)
	ui.end_turn_pressed.connect(ReseauManager.end_turn)
	ui.jail_pay_pressed.connect(ReseauManager.pay_jail)
	ui.jail_card_pressed.connect(func():
		var card_id = Global.cartes_prison.get(Global.my_client_id, -1)
		ReseauManager.use_jail_card(card_id)
	)

	# Connexions Réseau -> scène
	Reseau.tour_change.connect(_on_tour_change)
	Reseau.des_lances.connect(_on_des_lances)
	Reseau.propriete_achetee.connect(_on_propriete_achetee)
	Reseau.sorti_de_prison.connect(_on_sorti_de_prison)
	Reseau.maison_construite.connect(_on_maison_construite)
	Reseau.fin_tour.connect(_fin_tour)
	# FIX : était connecté à _sortir_prison (1 param) → le signal envoie 2 params,
	# et _sortir_prison ne nettoyait pas Global.cartes_prison.
	# On connecte maintenant à _on_use_card qui gère les deux arguments correctement.
	Reseau.carte_utilisee.connect(_on_use_card)
	SoundManager.play_music("music", SoundManager.lvl_music_settings)
	Reseau.jeu_termine.connect(_on_jeu_termine)
	Reseau.joueur_en_faillite.connect(_on_joueur_eliminé)

	# Attendre la fin de l'animation d'intro avant d'autoriser les contrôles
	board.intro_animation_finished.connect(_on_intro_animation_finished)

	_on_jeu_demarre()
	#ReseauManager.ready_next_turn()
func _on_intro_animation_finished():
	intro_en_cours = false
	_refresh_ui_state()

# ── Compteur de tours : mise à jour + animation ────────────────────────────
func _update_tour_label() -> void:
	if not tour_label:
		return
	if Global.number_turn_max == -1:
		tour_label.text = "Tours restants : %d" % Global.number_turn
	else:
		tour_label.text = "Tours restants : %d / %d" % [Global.number_turn, Global.number_turn_max]

	if intro_en_cours:
		return  # pas d'animation pendant l'intro

	# Laisser le layout calculer la taille avant d'animer le pivot
	await get_tree().process_frame
	tour_label.pivot_offset = tour_label.size / 2.0

	if Global.number_turn_max - Global.number_turn <= 2:
		# Urgence : rouge + clignotement rapide
		tour_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))
		var bounce = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		bounce.tween_property(tour_label, "scale", Vector2(1.35, 1.35), 0.1)
		bounce.tween_property(tour_label, "scale", Vector2(1.0,  1.0),  0.15)
		var pulse = create_tween().set_loops(4)
		pulse.tween_property(tour_label, "modulate:a", 0.25, 0.2)
		pulse.tween_property(tour_label, "modulate:a", 1.0,  0.2)
	else:
		tour_label.remove_theme_color_override("font_color")
		tour_label.modulate = Color.WHITE
		var bounce = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		bounce.tween_property(tour_label, "scale", Vector2(1.2, 1.2), 0.12)
		bounce.tween_property(tour_label, "scale", Vector2(1.0, 1.0), 0.18)

func _fin_tour(_player_id)->void:
	board.on_turn_end()  # day/night cycle (fire-and-forget)
	ReseauManager.ready_next_turn()
	return
# --- Initialisation du plateau ---
func _on_jeu_demarre():
	for p in Global.lobby_players:
		var id = p.get("clientID", -1)
		if id != -1:
			Global.positions_joueurs[id] = 0
	
	var nb_joueurs = Global.lobby_players.size()
	for i in range(player_containers.size()):
		player_containers[i].visible = (i < nb_joueurs)
	
	ui.setup_money_labels(Global.lobby_players, labels_argent)
	_refresh_ui_state()
	_refresh_all_patrimoines()
	var request = {
			"mainID": 2,
			"subID": 5,
			"clientID": Global.my_client_id,
			"data": {
				"matchID": Global.current_match_id
			}
		}
	Reseau.send_data(request)
	
func get_username(client_id: int) -> String:
	for player in Global.lobby_players:
		if player.get("clientID") == client_id:
			return player.get("username", "Joueur inconnu")
	return "Joueur " + str(client_id)

# ── Calcul et affichage du patrimoine ─────────────────────────────────────────

## Calcule le patrimoine total d'un joueur :
## argent liquide + valeur des propriétés + valeur des maisons/hôtels construits.
func calculate_patrimoine(client_id: int) -> int:
	var cash : int = ui.player_money_values.get(client_id, 0)
	var prop_value : int = 0
	for prop_id in Global.proprietes_joueurs:
		if Global.proprietes_joueurs[prop_id] == client_id:
			var prop : Dictionary = GameData.PROPERTIES.get(prop_id, {})
			prop_value += prop.get("price", 0)
			var houses : int = Global.maisons_proprietes.get(prop_id, 0)
			prop_value += houses * prop.get("house_cost", 0)
	return cash + prop_value

## Met à jour l'affichage patrimoine de tous les joueurs actifs.
func _refresh_all_patrimoines() -> void:
	for p in Global.lobby_players:
		var cid : int = int(p.get("clientID", -1))
		if cid != -1:
			log.update_patrimoine(cid, calculate_patrimoine(cid))

# --- Changement de tour ---
func _on_tour_change(new_id: int):
	var a_eu_faillite = (elimination > 0)
	while elimination != 0:
		await get_tree().process_frame
	if a_eu_faillite:
		await get_tree().create_timer(5).timeout
	current_player_id = new_id
	Global.current_client_id = current_player_id
	my_turn = (new_id == Global.my_client_id)
	des_deja_lances = false
	vient_de_sortir_prison = false
	des_en_cours = false
	doubles_consecutifs = 0       
	var username = get_username(new_id)

	#Global.number_turn -= 1
	_update_tour_label()
	if not intro_en_cours:
		ui.text_tour_change("C'est ton tour !" if my_turn else "Tour de " + str(username))
		# Focus caméra sur le pion du joueur actif dès le début de son tour,
		# avant même qu'il lance les dés (amélioration UX).
		board.focus_camera_on_player(new_id)
	_refresh_ui_state()

# --- Lancer de dés (reçu du serveur) ---
func _on_des_lances(payload: Dictionary):
	_movement_active = true   # posé AVANT tout await : PLAYER_ELIMINATED peut déjà être en route
	des_en_cours = true
	ui.set_controls(false, false)
	ui.hide_all_popups()
	vient_de_sortir_prison = false

	# Recadrage de la caméra sur le joueur actif avant l'animation des dés
	board.focus_camera_on_player(current_player_id)
	await get_tree().create_timer(0.4).timeout

	var d1 = int(payload.get("dice1", 0))
	var d2 = int(payload.get("dice2", 0))
	var card_id = int(payload.get("card", -1))
	var a_fait_double = (d1 == d2)

# =============================================================================
	# Animation des dés
	if ui.dice_ui:
		ui.dice_ui.show()
		await ui.dice_ui.run_dice_animation(d1, d2)
	if a_fait_double:
		if Global.classe2.has(current_player_id):
			await ui.update_money(current_player_id, 25)
			log.log_effet_classe(get_username(current_player_id), "Élite : +25 M bonus double !", current_player_id)
			print("Double fait")
			_refresh_all_patrimoines()
	
	var prison_data = Global.etat_prison.get(current_player_id, {"in_prison": false})
	
	# Annule un effacement de prison en attente (car on va le traiter ici)
	if pending_prison_clear and current_player_id == Global.my_client_id:
		pending_prison_clear = false
	
	if prison_data.in_prison:
		if a_fait_double:
			# Sortie par double : on libère immédiatement
			vient_de_sortir_prison = true
			des_deja_lances = true
			Global.etat_prison.erase(current_player_id)
		else:
			# Pas de double : on reste, tour fini
			Global.etat_prison[current_player_id]["tours_restants"] -= 1
			des_deja_lances = true
			des_en_cours = false
			_movement_active = false   # sortie anticipée : aucun déplacement prévu
			_refresh_ui_state()
			return
	else:
		# Hors prison : un double permet de rejouer
		des_deja_lances = !a_fait_double
	
	
		var prison_data_check = Global.etat_prison.get(current_player_id, {"in_prison": false})

		if not prison_data_check.in_prison and a_fait_double:
			doubles_consecutifs += 1
			print("Double consécutif n°", doubles_consecutifs, "pour le joueur", current_player_id)
			
			if doubles_consecutifs >= 3:
				print("🚨 3 DOUBLES CONSÉCUTIFS → Envoi en prison !")
				des_deja_lances = true
				des_en_cours = false
				_movement_active = false
				doubles_consecutifs = 0
				
				await _teleport_jail()
				_refresh_ui_state()
				return   # ← Important : on sort de la fonction, pas de déplacement
		else:
			doubles_consecutifs = 0
	# Déplacement
	var current_pos = Global.positions_joueurs.get(current_player_id, 0)
	var move = MonopolyLogic.calculate_move(current_pos, d1 + d2)

	board.flash_destination(move.new_pos, current_player_id)  # fire-and-forget
	await board.move_pion(current_player_id, current_pos, move.new_pos)
	Global.positions_joueurs[current_player_id] = move.new_pos
	log.start_new_turn_log(get_username(current_player_id), d1+d2, GameData.PROPERTIES[move.new_pos]["name"], current_player_id, move.new_pos)

	# ====================== EFFET CLASSE VOLEUR (CLASSE 1) ======================
	if Global.classe1.has(current_player_id):
		print("👤 Effet Voleur activé pour le joueur ", current_player_id)
		
		if Global.positions_joueurs[current_player_id] != 10:
			for other_id in Global.joueurs:
				if other_id != current_player_id:
					var other_pos = Global.positions_joueurs.get(other_id, 0)
					
					if other_pos == Global.positions_joueurs[current_player_id]:
						print("💰 Le Voleur est sur la même case que le joueur ", other_id)
						
						await board.play_rent_hurt(other_id,current_player_id)
						await ui.update_money(current_player_id, 200)
						await ui.update_money(other_id, -200)
						log.log_effet_classe(get_username(current_player_id), "Voleur : vole 200 M à " + get_username(other_id) + " !", current_player_id)
						_refresh_all_patrimoines()
						if ui.has_negative_balance():
							_movement_active = false
							des_en_cours = false
		
	# Passage par la case Départ
	if move.passed_start:
		var go_amount : int = Global.loyer_go + (75 if Global.classe3.has(current_player_id) else 0)
		await ui.update_money(current_player_id, go_amount)
		log.log_passe_depart(get_username(current_player_id), go_amount, current_player_id)
		if Global.classe3.has(current_player_id):
			log.log_effet_classe(get_username(current_player_id), "Départ : +75 M bonus classe !", current_player_id)
		await get_tree().create_timer(1).timeout
	# Résolution de la case (carte ou action)
	if card_id >40:
		await _afficher_carte(card_id)
	else:
		await _analyser_case(move.new_pos, d1 + d2)
	
	# Nettoyage final d'un éventuel pending (sécurité)
	if pending_prison_clear and current_player_id == Global.my_client_id:
		pending_prison_clear = false
		Global.etat_prison.erase(current_player_id)

	# Tout le tour est terminé (déplacement + Voleur + analyse case)
	# → on libère le verrou AVANT de déverrouiller l'UI
	_movement_active = false
	des_en_cours = false
	_refresh_all_patrimoines()
	_refresh_ui_state()

# --- Analyse de la case après déplacement ---
func _analyser_case(pos: int, dice_sum: int):
	var type_case = MonopolyLogic.resolve_case_type(pos)
	if pos == 12:
		SoundManager.play_eau()
	if pos == 28:
		SoundManager.play_electrcite()
	match type_case:
		MonopolyLogic.CaseType.PROPERTY, MonopolyLogic.CaseType.STATION, MonopolyLogic.CaseType.UTILITY:
			if type_case == MonopolyLogic.CaseType.STATION:
				SoundManager.play_train()
			var owner = Global.proprietes_joueurs.get(pos, -1)
			if owner == -1:
				if my_turn:
					var prop = GameData.PROPERTIES.get(pos,{})
					var prix_prop = prop.get("price",0)
					var argent_dispo = ui.player_money_values.get(current_player_id,0)
					
					if argent_dispo < prix_prop:
						print("pas assez d'argent pour acheter, skip")
					else:
						ui.show_popup("achat", pos,current_player_id)
						var accepted = await ui.buy_decision_received
						if accepted:
						# On lance l'action réseau
							ReseauManager.buy_property(pos)
							print("Achat validé, requête envoyée au serveur.")
						else:
							print("Le joueur a refusé l'achat.")
			elif owner != current_player_id:
				var houses = Global.maisons_proprietes.get(pos, 0)
				var rent = MonopolyLogic.get_rent(pos, houses, dice_sum, owner)
				$CanvasLayer/Control/popup_loyer.setup_popup(get_username(owner),pos,rent)
				SoundManager.play_loyer()
				ui.update_money(current_player_id, -rent)
				ui.update_money(owner, rent)
				Global.add_loyer(owner, rent)   # ← stat : loyer encaissé
				log.log_payer_loyer(get_username(current_player_id), get_username(owner), GameData.PROPERTIES.get(pos, {}).get("name", "?"), rent, current_player_id, owner, pos)
				await get_tree().create_timer(1.5).timeout
			else:
				if my_turn:
					if type_case== MonopolyLogic.CaseType.PROPERTY:
						ui.show_popup_maison(pos)
		
		MonopolyLogic.CaseType.TAX:
			var nom_taxe = "taxe_impot" if pos == 4 else "taxe_luxe"
			ui.show_popup(nom_taxe)
			var montant = -200 if pos == 4 else -150
			ui.update_money(current_player_id, montant)
			log.log_taxe(get_username(current_player_id), pos == 4, abs(montant), current_player_id)
			await ui.popup_finished
		
		MonopolyLogic.CaseType.GO_TO_JAIL:
			await _teleport_jail()
		
		MonopolyLogic.CaseType.CHANCE, MonopolyLogic.CaseType.COMMUNITY:
			# Déjà traité via card_id dans _on_des_lances, ne rien faire
			pass
		
		_: # START, PARKING, JAIL_VISIT
			await get_tree().create_timer(0.5).timeout

# --- Affichage et exécution d'une carte Chance / Caisse ---
func _afficher_carte(card_id: int):
	var type_popup = "chance" if (card_id >= 100 and card_id < 200) else "community"
	var popup_node = ui.popups[type_popup]
	ui.show_popup(type_popup, card_id)
	await popup_node.visibility_changed
	var effect_data = MonopolyLogic.get_card_effect(card_id)
	var card_dict = GameData.CHANCE_CARDS.get(card_id, GameData.COMMUNITY_CHEST_CARDS.get(card_id, {}))
	log.log_carte(get_username(current_player_id), card_dict.get("text", "Carte " + str(card_id)), card_dict.get("type", "neutral"), current_player_id)
	await _appliquer_effet_carte(effect_data)

func _appliquer_effet_carte(data: Dictionary):
	var effect = data.get("effect", "")
	var amount = data.get("amount", 0)
	
	match effect:
		"go_to_jail":
			await _teleport_jail()
		"receive_money", "pay_money":
			ui.update_money(current_player_id, amount)
		"move_to_start":
			var current_pos = Global.positions_joueurs.get(current_player_id, 0)
			await board.move_pion(current_player_id, current_pos, 0)
			Global.positions_joueurs[current_player_id] = 0
			var go_amount_2 : int = Global.loyer_go + (75 if Global.classe3.has(current_player_id) else 0)
			ui.update_money(current_player_id, go_amount_2)  # 200 M
		"get_out_jail_free":
			Global.cartes_prison[current_player_id] = data.get("card_id",-1)
			log.update_prison_card_icon(current_player_id, true)
		_:
			print("Effet inconnu : ", effect)

# --- Achat d'une propriété (broadcast serveur) ---
func _on_propriete_achetee(client_id: int, prop_id: int):
	Global.proprietes_joueurs[prop_id] = client_id
	var prop = GameData.PROPERTIES.get(prop_id)
	ui.update_money(client_id,-prop.get("price"))
	board.highlight_property(prop_id, client_id)
	log.log_achat_propriete(get_username(client_id), prop.get("name", "?"), client_id, prop_id)
	ui.hide_all_popups()
	_refresh_ui_state()
	_refresh_all_patrimoines()

# --- Construction de maison / hôtel (Confirmé par le serveur) ---
func _on_maison_construite(payload: Dictionary):
	var prop_id = int(payload.get("propertyID", -1))
	var client_id = int(payload.get("clientID", -1))
	var total = int(payload.get("totalHouses", 0)) # Le nouveau total envoyé par le serveur

	var ancien_total = Global.maisons_proprietes.get(prop_id, 0)
	var nb_ajoutees = total - ancien_total
	
	Global.maisons_proprietes[prop_id] = total
	var prop_data = GameData.PROPERTIES.get(prop_id, {})
	print(prop_data)
	var cost_per_unit = prop_data.get("house_cost", 0)
	print("cost_per_unit:", cost_per_unit)
	var cost_total = int(nb_ajoutees* cost_per_unit)
	cost_total = cost_total * (-1)
	ui.update_money(client_id, cost_total)
	
	var has_hotel = (total >= 5)
	
	board.place_buildings(prop_id, total, has_hotel, client_id)
	var prop_name = GameData.PROPERTIES.get(prop_id, {}).get("name", "?")
	log.log_construction(get_username(client_id), prop_name, nb_ajoutees, total, client_id, prop_id)

	_refresh_all_patrimoines()
	if client_id == Global.my_client_id:
		ui.hide_all_popups()
		_refresh_ui_state()

# --- Sortie de prison (signal serveur) ---
func _on_sorti_de_prison(client_id: int):
	# Si le joueur concerné est en plein lancer, on retarde l'effacement
	ui.update_money(client_id,-50)
	if des_en_cours and client_id == current_player_id:
		pending_prison_clear = true
	else:
		Global.etat_prison.erase(client_id)
		if client_id == Global.my_client_id and not des_en_cours:
			ui.hide_all_popups()
			_refresh_ui_state()

# --- Met à jour les boutons selon l'état du tour ---
func _refresh_ui_state():
	if intro_en_cours or not my_turn or des_en_cours:
		ui.set_controls(false, false)
		return
	
	if vient_de_sortir_prison:
		ui.set_controls(false, true)   # seulement End Turn
		return
	
	var prison = Global.etat_prison.get(Global.my_client_id, {"in_prison": false})
	if prison.in_prison:
		if not des_deja_lances:
			ui.update_prison_ui(prison.tours_restants, Global.cartes_prison.has(Global.my_client_id))
			ui.set_controls(false, false)
		else:
			ui.set_controls(false, true)
		return
	
	# Tour normal
	ui.set_controls(!des_deja_lances, des_deja_lances)

# Renvoie la direction visuelle ("vers la gauche", "vers le haut", etc.)
# selon le côté du plateau où le pion se trouve actuellement. Le sens du
# Monopoly est toujours horaire, donc la direction visuelle dépend du côté.
func _move_direction_label(from_pos: int) -> String:
	if from_pos <= 10:    return "↞ vers la gauche"
	if from_pos <= 19:    return "↟ vers le haut"
	if from_pos <= 30:    return "↠ vers la droite"
	return "↡ vers le bas"

# --- Envoi en prison (téléportation + logique) ---
func _teleport_jail():
	var id_prisonnier = current_player_id
	Global.etat_prison[id_prisonnier] = {"in_prison": true, "tours_restants": 3}
	Global.positions_joueurs[id_prisonnier] = 10
	Global.add_prison(id_prisonnier)   # ← stat : passage en prison
	await board.play_prison_animation(id_prisonnier)
	
	if my_turn:
		des_deja_lances = true
		ui.hide_all_popups()
		ui.set_controls(false, true)
		
		
# --- Use card suite à push server ---
func _on_use_card(clientID: int, cardID: int):
	# Toute carte de sortie de prison (Chance 103, Caisse de Communauté 203)
	# déclenche la libération. On garde la vérification au cas où d'autres
	# types de cartes utilisables seraient ajoutés plus tard.
	if cardID == 103 or cardID == 203:
		_sortir_prison(clientID, cardID)
	else:
		print("Carte utilisée non gérée côté client : cardID=", cardID)

# --- Sortir de prison par carte (push serveur) ---
func _sortir_prison(clientID: int, _cardID: int = -1):
	# 1. Nettoyer l'état prison
	Global.etat_prison.erase(clientID)          # FIX : erase() au lieu de set à false
	# 2. Retirer la carte de la main du joueur
	Global.cartes_prison.erase(clientID)        # FIX : la carte est consommée
	# 3. Mettre à jour l'icône HUD
	log.update_prison_card_icon(clientID, false)
	if my_turn and clientID == Global.my_client_id:
		ui.hide_all_popups()
		des_deja_lances = false
		_refresh_ui_state()   # FIX : utiliser _refresh_ui_state() pour remettre les boutons proprement
		
# --- Elimination d'un joueur ---
func _on_joueur_eliminé(client_id: int):
	elimination += 1
	# _movement_active est posé à true dès le début de _on_des_lances (avant tout await),
	# donc il est déjà vrai quand ce handler démarre si DICE_ROLLED est arrivé avant.
	# Le petit délai couvre le cas extrême où les deux messages WebSocket arriveraient
	# dans le même frame Godot.
	await get_tree().create_timer(0.3).timeout
	while _movement_active:
		await get_tree().create_timer(0.05).timeout

	# Bloquer l'UI si c'est le joueur local
	if client_id == Global.my_client_id:
		ui.set_controls(false, false)
		ui.hide_all_popups()

	log.log_faillite(get_username(client_id), client_id)

	# ── Animations simultanées : pion 3D + slot HUD (fire-and-forget pour le HUD)
	log.play_slot_elimination(client_id)          # HUD : flashs + skull + fondu
	await board.play_bankruptcy_animation(client_id)  # 3D  : spin + enfoncement

	# Nettoyer propriétés et bâtiments
	for property_id in Global.proprietes_joueurs.keys():
		if Global.proprietes_joueurs[property_id] == client_id:
			board.clear_property_highlight(property_id)
			board.clear_buildings(property_id)

	# Supprimer le pion (déjà enfoncé dans le sol par l'animation 3D)
	if board._pawns.has(client_id):
		board._pawns[client_id].queue_free()
		board._pawns.erase(client_id)
	board._pawn_indices.erase(client_id)

	MonopolyLogic.cleanup_player(client_id)

	elimination -= 1
# --- Fin du jeu ---
func _on_jeu_termine(winner_id: int, classement: Array):
	des_en_cours = false          # débloque les await sur buy_decision / UI
	# NE PAS forcer _movement_active = false ici :
	# si GAME_ENDED arrive en même temps que PLAYER_ELIMINATED, _on_joueur_eliminé
	# attend que _movement_active repasse à false naturellement (fin du tour).
	# Forcer false ici court-circuiterait cette attente et jouerait l'animation trop tôt.
	ui.set_controls(false, false)
	ui.hide_all_popups()
	Global.classement_final = classement

	# 1. Attendre que le tour en cours se termine (déplacement + Voleur + case)
	var t : float = 0.0
	while _movement_active and t < 15.0:
		await get_tree().create_timer(0.1).timeout
		t += 0.1
	_movement_active = false  # sécurité après timeout

	# 2. Attendre que les animations de faillite se jouent (avec timeout de sécurité)
	t = 0.0
	while elimination > 0 and t < 10.0:
		await get_tree().create_timer(0.1).timeout
		t += 0.1

	# Petit délai pour laisser la scène se stabiliser
	await get_tree().create_timer(1.0).timeout

	# ── 1. Séquence cinématique 3D ────────────────────────────────────────────
	await board.play_victory_sequence(winner_id)

	# ── 2. Écran de fin 2D ────────────────────────────────────────────────────
	var EndGameScript : GDScript = load("res://scripts/ui/EndGameScreen.gd")
	if EndGameScript == null:
		push_error("EndGameScreen: script introuvable à res://scripts/ui/EndGameScreen.gd")
		return
	var end_screen : CanvasLayer = EndGameScript.new()
	end_screen.set("winner_id",  winner_id)
	end_screen.set("classement", classement)
	end_screen.set("scene_ref",  self)
	add_child(end_screen)
	
