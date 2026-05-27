# LobbyJoin.gd
extends Control

@onready var code_line_edit: LineEdit = $Panel/Content/CodeSection/CodeLineEdit

func _ready() -> void:
	# Connexion au signal (qui envoie maintenant tout le dictionnaire "data")
	if not Reseau.lobby_rejoint.is_connected(_on_lobby_rejoint):
		Reseau.lobby_rejoint.connect(_on_lobby_rejoint)

# ==================== BOUTON REJOINDRE ====================
func _on_join_button_pressed() -> void:
	SoundManager.play_clique()
	var code_text = code_line_edit.text.strip_edges()
	
	if code_text == "" or not code_text.is_valid_int():
		print("❌ Code du lobby invalide !")
		return
	
	var match_id = int(code_text)
	
	# On stocke immédiatement ce qu’on connaît
	Global.current_match_id = match_id
	Global.is_host = false                     # On n'est PAS l'hôte
	Global.lobby_players.clear()               # On vide avant de recevoir les vraies données
	
	
	# Envoi de la requête JOIN_LOBBY
	var request_data = {
		"mainID": 2,
		"subID": 3,
		"clientID": Global.my_client_id,
		"data": {
			"matchID": match_id,
			"username": Global.my_username
		}
	}
	
	Reseau.send_data(request_data)
	print("➡️ Demande de rejoindre le lobby ", match_id)

# ==================== RÉCEPTION DU SIGNAL (LobbyJoin.gd) ====================
func _on_lobby_rejoint(lobby_data: Dictionary) -> void:
	print("✅ Lobby rejoint avec succès ! Configuration de Global...")
	
	# 1. Nettoyage de sécurité
	Global.lobby_players.clear()
	Global.classe1.clear()
	Global.classe2.clear()
	Global.classe3.clear()
	
	# 2. Remplissage des paramètres (Conversion int pour éviter le bug des floats)
	Global.number_turn      = int(lobby_data.get("numberTurn", 999))
	Global.argent_depart    = int(lobby_data.get("moneyStart", 1500))
	Global.lobby_players    = lobby_data.get("players", [])
	
	# 3. Distribution immédiate des joueurs dans les tableaux de classes
	for p in Global.lobby_players:
		var c_id = int(p.get("clientID", -1))
		var class_id = int(p.get("classID", 0))
		
		match class_id:
			1: Global.classe1.append(c_id)
			2: Global.classe2.append(c_id)
			3: Global.classe3.append(c_id)
	
	print("📋 Données Global prêtes. Changement de scène...")
	
	# 4. Changement de scène
	var err = get_tree().change_scene_to_file("res://scenes/Menu/LobbyScreen.tscn")
	if err != OK:
		push_error("❌ Erreur changement de scène : " + str(err))

# ==================== BOUTON RETOUR ====================
func _on_back_button_pressed() -> void:
	SoundManager.play_clique_negatif()
	$".".hide()
