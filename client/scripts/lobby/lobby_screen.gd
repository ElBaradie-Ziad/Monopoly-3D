extends Control

# ====================== RÉFÉRENCES UI ======================
@onready var code_value: Label = $MainPanel/MarginContainer/Content/Info/MarginContainer/InfoPanel/GameCodeSection/CodeValue
@onready var turn_value: Label = $MainPanel/MarginContainer/Content/Info/MarginContainer/InfoPanel/GameSettings/HBoxContainer/TurnValue
@onready var money_value: Label = $MainPanel/MarginContainer/Content/Info/MarginContainer/InfoPanel/GameSettings/HBoxContainer2/MoneyValue

const ICON_CLASSE_1 = preload("res://design_raw/ui_ux/voleur_classe.png")
const ICON_CLASSE_2 = preload("res://design_raw/ui_ux/double_classe.png")
const ICON_CLASSE_3 = preload("res://design_raw/ui_ux/case_depart_classe.png")

# Dictionnaire mis à jour avec les Avatars
@onready var player_labels = {
	1: {
		"pseudo": $MainPanel/MarginContainer/Content/PlayersPanel/Panel/MarginContainer/PlayersContainer/Player1/MarginContainer/ElementsPlayer/VBoxContainer/pseudo, 
		"status": $MainPanel/MarginContainer/Content/PlayersPanel/Panel/MarginContainer/PlayersContainer/Player1/MarginContainer/ElementsPlayer/VBoxContainer/readystatus,
		"avatar": $MainPanel/MarginContainer/Content/PlayersPanel/Panel/MarginContainer/PlayersContainer/Player1/MarginContainer/ElementsPlayer/Avatar,
		"container": null
	},
	2: {
		"pseudo": $MainPanel/MarginContainer/Content/PlayersPanel/Panel/MarginContainer/PlayersContainer/Player2/MarginContainer/ElementsPlayer/VBoxContainer/pseudo, 
		"status": $MainPanel/MarginContainer/Content/PlayersPanel/Panel/MarginContainer/PlayersContainer/Player2/MarginContainer/ElementsPlayer/VBoxContainer/readystatus,
		"avatar": $MainPanel/MarginContainer/Content/PlayersPanel/Panel/MarginContainer/PlayersContainer/Player2/MarginContainer/ElementsPlayer/Avatar,
		"container": $MainPanel/MarginContainer/Content/PlayersPanel/Panel/MarginContainer/PlayersContainer/Player2
	},
	3: {
		"pseudo": $MainPanel/MarginContainer/Content/PlayersPanel/Panel/MarginContainer/PlayersContainer/Player3/MarginContainer/ElementsPlayer/VBoxContainer/pseudo, 
		"status": $MainPanel/MarginContainer/Content/PlayersPanel/Panel/MarginContainer/PlayersContainer/Player3/MarginContainer/ElementsPlayer/VBoxContainer/readystatus,
		"avatar": $MainPanel/MarginContainer/Content/PlayersPanel/Panel/MarginContainer/PlayersContainer/Player3/MarginContainer/ElementsPlayer/Avatar,
		"container": $MainPanel/MarginContainer/Content/PlayersPanel/Panel/MarginContainer/PlayersContainer/Player3
	},
	4: {
		"pseudo": $MainPanel/MarginContainer/Content/PlayersPanel/Panel/MarginContainer/PlayersContainer/Player4/MarginContainer/ElementsPlayer/VBoxContainer/pseudo, 
		"status": $MainPanel/MarginContainer/Content/PlayersPanel/Panel/MarginContainer/PlayersContainer/Player4/MarginContainer/ElementsPlayer/VBoxContainer/readystatus,
		"avatar": $MainPanel/MarginContainer/Content/PlayersPanel/Panel/MarginContainer/PlayersContainer/Player4/MarginContainer/ElementsPlayer/Avatar,
		"container": $MainPanel/MarginContainer/Content/PlayersPanel/Panel/MarginContainer/PlayersContainer/Player4
	}
}

@onready var class_panels = [
	$"MainPanel/MarginContainer/Content/PlayerClass/MarginContainer/VBoxContainer/Classe 1",
	$"MainPanel/MarginContainer/Content/PlayerClass/MarginContainer/VBoxContainer/Classe 2",
	$"MainPanel/MarginContainer/Content/PlayerClass/MarginContainer/VBoxContainer/Classe 3"
]

@onready var rdy_button: Button = $MainPanel/MarginContainer/Content/Info/MarginContainer/InfoPanel/MarginContainer/rdy

# ====================== VARIABLES DE GESTION ======================
var ready_players: Dictionary = {} # clientID (int) -> bool
var selected_color = Color(1.0, 0.9, 0.0, 0.55)
var idle_color = Color(1.0, 0.9, 0.0, 0.0)
var is_launching: bool = false
# ====================== INITIALISATION ======================
# Dans LobbyScreen.gd

func _ready() -> void:
	print("🚀 LobbyScreen chargée - Synchronisation avec Global")
	# 1. On initialise le dictionnaire local ready_players à partir de Global
	ready_players.clear()
	for p in Global.lobby_players:
		var c_id = int(p.get("clientID", -1))
		ready_players[c_id] = bool(p.get("ready", false))
	
	# 2. Mise à jour des textes (Code, Tours, Argent)
	code_value.text = str(Global.current_match_id) if Global.current_match_id != -1 else "-----"
	turn_value.text = "Illimité" if Global.number_turn_max == 999 or Global.number_turn_max == -1 else str(Global.number_turn_max) + " tours"
	money_value.text = str(Global.argent_depart) + " M"
	
	# 3. Connexion des signaux pour les mises à jour EN DIRECT (pendant qu'on est sur l'écran)
	Reseau.joueur_rejoint_lobby.connect(_on_joueur_rejoint_lobby)
	Reseau.joueur_quitte_lobby.connect(_on_joueur_quitte_lobby)
	Reseau.joueur_ready.connect(_on_joueur_ready)
	rdy_button.pressed.connect(_on_rdy_button_pressed)
	
	# 4. Configuration visuelle
	for i in range(class_panels.size()):
		class_panels[i].gui_input.connect(_on_class_gui_input.bind(i + 1))
	
	_setup_avatar_formats() # La boucle de configuration 64x64 que nous avons faite
	_update_class_visuals()
	_update_players_list()   # affichera les avatars car Global.classeX est rempli
	_update_ready_statuses() # affichera les "Prêt" car ready_players est rempli
	
	# 5. On vérifie si par hasard tout le monde est déjà prêt
	_check_launch_condition()
	$MainPanel/MarginContainer/Content/Info/MarginContainer/InfoPanel/MarginContainer/Erreur.hide()

	
func _setup_avatar_formats() -> void:
	for i in range(1, 5):
		var avatar = player_labels[i].avatar
		if avatar:
			# On force la taille du rectangle
			avatar.custom_minimum_size = Vector2(64, 64)
			# IMPORTANT : Permet au Rect de ne pas s'agrandir selon la taille du PNG
			avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE 
			# On garde les proportions et on centre l'image dans les 64x64
			avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
# ====================== SYNCHRONISATION SERVEUR (SUBID: 3) ======================
# Cette fonction doit être appelée par ton script Reseau lors de la réception du snapshot
func setup_lobby_from_server(data: Dictionary) -> void:
	# 1. Nettoyage complet pour repartir sur une base saine
	Global.lobby_players.clear()
	Global.classe1.clear()
	Global.classe2.clear()
	Global.classe3.clear()
	ready_players.clear()
	
	
	

	# 2. Récupération de la liste des joueurs (Structure : data -> players)
	var players_list = []
	if data.has("data") and data["data"].has("players"):
		players_list = data["data"]["players"]
	else:
		print("⚠️ Structure JSON inattendue : clé 'players' introuvable")
		return

	print("📊 Synchronisation initiale : ", players_list.size(), " joueurs trouvés.")

	# 3. Traitement de chaque joueur
	for p in players_list:
		# Conversion FORCEE en int (6.0 -> 6) pour les IDs
		var c_id = int(p.get("clientID", -1))
		var is_rdy = bool(p.get("ready", false))
		var class_id = int(p.get("classID", 0))
		var username = p.get("username", "Inconnu")

		# Ajout à la liste globale des joueurs
		Global.lobby_players.append({
			"clientID": c_id,
			"username": username
		})
		
		# Enregistrement du statut prêt (clé int obligatoire)
		ready_players[c_id] = is_rdy
		
		# Assignation de la classe et mise à jour de l'avatar
		if class_id > 0:
			_assign_to_class_array(c_id, class_id)
		
		print("👤 Joueur synchronisé : ", username, " | ID: ", c_id, " | Prêt: ", is_rdy, " | Classe: ", class_id)

	# 4. Rafraîchissement complet de l'interface
	_update_players_list()
	_update_ready_statuses()
	
	# 5. Vérification si on peut déjà lancer (si tout le monde est prêt)
	_check_launch_condition()
# ====================== GESTION DES CLASSES ======================
func _on_class_gui_input(event: InputEvent, class_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Global.select_classe = class_index
		_update_class_visuals()
		print("🎯 Classe choisie : ", Global.select_classe)
		SoundManager.play_clique()


func _update_class_visuals() -> void:
	for i in range(class_panels.size()):
		var color_rect = class_panels[i].get_node("ColorRect")
		if (i + 1) == Global.select_classe:
			color_rect.color = selected_color
		else:
			color_rect.color = idle_color

func _assign_to_class_array(c_id: int, class_id: int) -> void:

	Global.classe1.erase(c_id)
	Global.classe2.erase(c_id)
	Global.classe3.erase(c_id)
	match class_id:
		1: Global.classe1.append(c_id)
		2: Global.classe2.append(c_id)
		3: Global.classe3.append(c_id)
	_update_players_list()
# ====================== MISE À JOUR LISTE & READY ======================
func _update_players_list() -> void:
	var players = Global.lobby_players
	
	for i in range(1, 5):
		var ui = player_labels[i]
		if (i - 1) < players.size():
			var p_data = players[i-1]
			var c_id = int(p_data.clientID)
			ui.pseudo.text = p_data.get("username", "Joueur " + str(p_data.clientID))
			# --- NOUVEAU : Mise à jour de l'Avatar selon la classe ---
			if Global.classe1.has(c_id):
				ui.avatar.texture = ICON_CLASSE_1
			elif Global.classe2.has(c_id):
				ui.avatar.texture = ICON_CLASSE_2
			elif Global.classe3.has(c_id):
				ui.avatar.texture = ICON_CLASSE_3
			else:
				ui.avatar.texture = null # Ou une icône de point d'interrogation
			if ui.container: ui.container.visible = true
		else:
			if ui.container: ui.container.visible = false

func _update_ready_statuses() -> void:
	for i in range(1, 5):
		var ui = player_labels[i]
		ui.status.text = "En attente"
		ui.status.modulate = Color(0.7, 0.7, 0.7)
		
		if (i - 1) < Global.lobby_players.size():
			var c_id = int(Global.lobby_players[i-1].get("clientID", -1))
			if ready_players.get(c_id, false):
				ui.status.text = "Prêt"
				ui.status.modulate = Color(0.0, 1.0, 0.0)

# ====================== ÉVÉNEMENTS RÉSEAU ======================
func _on_joueur_rejoint_lobby(c_id: int, username: String, is_ready: bool, p_class: int) -> void:
	# Éviter les doublons
	if Global.lobby_players.any(func(p): return p.clientID == c_id): return
	
	Global.lobby_players.append({"clientID": c_id, "username": username})
	ready_players[c_id] = is_ready
	_assign_to_class_array(c_id, p_class)
	
	_update_players_list()
	_update_ready_statuses()

func _on_joueur_quitte_lobby(c_id: int) -> void:
	Global.lobby_players = Global.lobby_players.filter(func(p): return p.clientID != c_id)
	ready_players.erase(c_id)
	Global.classe1.erase(c_id)
	Global.classe2.erase(c_id)
	Global.classe3.erase(c_id)
	_update_players_list()
	_update_ready_statuses()

func _on_joueur_ready(c_id_float, class_id_float = 0) -> void:
	var c_id = int(c_id_float)
	var class_id = int(class_id_float)
	
	ready_players[c_id] = true
	
	# Ajout crucial : On assigne la classe pour mettre à jour les tableaux Global
	# et on rafraîchit la liste (l'avatar sera mis à jour via _assign_to_class_array)
	if class_id > 0:
		_assign_to_class_array(c_id, class_id)
	
	_update_ready_statuses()
	_check_launch_condition()

# ====================== ACTIONS ET LANCEMENT ======================
func _on_rdy_button_pressed() -> void:
	if Global.select_classe == 0:
		SoundManager.play_clique_negatif()
		$MainPanel/MarginContainer/Content/Info/MarginContainer/InfoPanel/MarginContainer/Erreur.show()
		return
	$MainPanel/MarginContainer/Content/Info/MarginContainer/InfoPanel/MarginContainer/Erreur.hide()
	SoundManager.play_clique()

	var request = {
		"mainID": 2,
		"subID": 4,
		"clientID": Global.my_client_id,
		"data": {
			"matchID": Global.current_match_id,
			"classID": Global.select_classe
		}
	}
	Reseau.send_data(request)
	ready_players[Global.my_client_id] = true
	_assign_to_class_array(Global.my_client_id, Global.select_classe)
	_update_ready_statuses()
	_check_launch_condition()
	SoundManager.play_clique()

func _check_launch_condition() -> void:
	# 1. On vérifie d'abord qu'il y a au moins 2 joueurs connectés
	var player_count = Global.lobby_players.size()
	
	if player_count < 2:
		# On peut afficher un message console ou un label discret dans l'UI
		print("⏳ Attente de joueurs (Minimum 2). Actuellement : ", player_count)
		return
	
	# 2. Si on est au moins 2, on vérifie si TOUT LE MONDE est prêt
	var all_ready = true
	for p in Global.lobby_players:
		var client_id = int(p.get("clientID", -1))
		if not ready_players.get(client_id, false):
			all_ready = false
			break
	
	# 3. Lancement uniquement si les deux conditions sont remplies
	if all_ready:
		_launch_game()

func _launch_game() -> void:
	if is_launching: return # Sécurité : on ne lance qu'une fois
	
	# Vérification de sécurité sur l'existence du Tree
	var tree = get_tree()
	if tree == null:
		print("⚠️ Tentative de lancement alors que la scène est déjà déchargée.")
		return

	is_launching = true
	print("🚀 TOUS PRÊTS : LANCEMENT...")
	await tree.create_timer(3.0).timeout
	Global.joueurs.clear()
	Global.player_color_index.clear()
	for i in range(Global.lobby_players.size()):
		var cid : int = int(Global.lobby_players[i].clientID)
		Global.joueurs.append(cid)
		Global.player_color_index[cid] = i  # couleur permanente, jamais modifiée
	Global.number_turn = 0
	
	# Utilisation de deferred pour laisser le temps au réseau de finir ses calculs
	
	tree.call_deferred("change_scene_to_file", "res://main.tscn")
	
	
func _on_lobby_leave_pressed() -> void:
	# 1. Construction de la requête selon le protocole
	var request = {
		"mainID": 2,
		"subID": 2,
		"clientID": Global.my_client_id,
		"data": {
			"matchID": Global.current_match_id
		}
	}
	
	# 2. Envoi au serveur
	Reseau.send_data(request)
	print("📤 Départ du lobby envoyé au serveur")
	SoundManager.play_clique_negatif()

	# 3. Nettoyage des données locales avant de partir
	_cleanup_lobby_data()
	
	# 4. Changement de scène (Relance la scène principale/menu)
	# Remplace "res://menu.tscn" par le chemin exact de ton menu principal
	var err = get_tree().change_scene_to_file("res://main_menu_v2.tscn")
	if err != OK:
		push_error("❌ Erreur lors du changement vers la scène principale : " + str(err))

func _cleanup_lobby_data() -> void:
	Global.current_match_id = -1
	Global.lobby_players.clear()
	Global.joueurs.clear()
	Global.classe1.clear()
	Global.classe2.clear()
	Global.classe3.clear()
	ready_players.clear()
	
	
# ====================== FONCTION CLEANER ======================
