extends Node

# --- Config ---
var socket := WebSocketPeer.new()
var url = "wss://185.155.93.105:19000" # Schéma complet requis par WebSocketPeer
var _was_connected := false

# --- Signaux Authentification ---
signal login_reussi
signal register_reussi
signal login_echec
signal register_echec

# --- Signaux Lobby ---
signal lobby_cree(match_id: int)
signal lobby_rejoint(lobby_data: Dictionary)
signal lobby_quitte
signal partie_demarree(data: Dictionary)
signal joueur_ready(client_id: int)

# --- Signaux Server Push (Lobby) ---
signal joueur_rejoint_lobby(client_id: int, username: String)
signal joueur_quitte_lobby(client_id: int)
signal jeu_demarre(data: Dictionary)

# --- Signaux Server Push (Jeu) ---
signal tour_change(current_client_id: int)
signal fin_tour(client_id: int)
signal des_lances(data: Dictionary)
signal propriete_achetee(client_id: int, property_id: int)
signal maison_construite(data: Dictionary)
signal hotel_construit(data: Dictionary)
signal sorti_de_prison(client_id: int)
signal joueur_en_faillite(client_id: int)
signal jeu_termine(winner_id: int, classement:Array)
signal carte_utilisee(client_id: int, card_id: int)

# --- Signaux Server Push (Snapshot) ---
signal snapshot_recu(state: Dictionary)


func _ready():
	# --- MODIFICATION ICI ---
	# Crée une configuration TLS qui accepte les certificats auto-signés (Pour le DEV uniquement)
	var tls_options = TLSOptions.client_unsafe()
	
	# Passe cette configuration en deuxième paramètre de connect_to_url
	var err = socket.connect_to_url(url, tls_options)
	
	if err != OK:
		print("Impossible d'initier la connexion : ", err)
	else:
		print("Connexion initiée avec TLS Unsafe")


func _process(_delta):
	socket.poll()

	var state = socket.get_ready_state()

	match state:
		WebSocketPeer.STATE_OPEN: 
			if not _was_connected:  # ← seulement la première fois
				print("Connecté au serveur !")
			_was_connected = true
			while socket.get_available_packet_count() > 0:
				var packet = socket.get_packet()
				_on_data_received(packet)

		WebSocketPeer.STATE_CLOSED:
			if _was_connected:
				_was_connected = false
				var code = socket.get_close_code()
				var reason = socket.get_close_reason()
				print("Connexion fermée. Code : %d, Raison : %s" % [code, reason])

		WebSocketPeer.STATE_CONNECTING:
			pass

		WebSocketPeer.STATE_CLOSING:
			pass


# --- ENVOI ---
func send_data(data: Dictionary):
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("Erreur : Socket non connecté.")
		return

	var json_string = JSON.stringify(data)
	socket.send_text(json_string)
	print("Envoi : ", json_string)




# --- RÉCEPTION ET ROUTAGE ---
func _on_data_received(packet: PackedByteArray):
	var text = packet.get_string_from_utf8()
	var msg = JSON.parse_string(text)

	if msg == null:
		print("Erreur : JSON invalide reçu.")
		return

	var mainID = int(msg.get("mainID", -1))
	var subID = int(msg.get("subID", -1))
	var erreur = msg.get("erreur", false)

	print("Reçu du serveur : ", msg)

	match mainID:
		# Premier echange avec le serveur et réception du clientID
		0:
			var test1 = msg.get("data", 0)
			Global.my_client_id = int(test1.get("clientID", 0))
			print("Client ID : ", Global.my_client_id)
		1: # Authentification
			_handle_auth(subID, erreur, msg.get("data", {}))
		2: # Lobby
			_handle_lobby(subID, erreur, msg.get("data", {}))
		3: # Jeu
			_handle_game(subID, erreur, msg.get("data", {}))
		4: # Server Push
			_handle_server_push(subID, msg.get("data", {}))
		_:
			print("mainID inconnu : ", mainID)


# --- HANDLERS SPÉCIFIQUES ---

func _handle_auth(subID: int, erreur: bool, data: Dictionary):
	match subID:
		1: # LOGIN
			if not erreur:
				print("Connexion réussie ! ID : ", Global.my_client_id)
				login_reussi.emit()
			else:
				print("Erreur login : ", data.get("messageErreur", "Inconnue"))
				login_echec.emit()

		2: # LOGOUT
			print("Déconnecté du serveur.")

		3: # REGISTER
			if not erreur:
				register_reussi.emit()
			else:
				print("Erreur inscription : ", data.get("messageErreur", "Inconnue"))
				register_echec.emit()

func _handle_lobby(subID: int, erreur: bool, data: Dictionary):
	match subID:
		1: # CREATE_LOBBY
			if not erreur:
				var match_id = data.get("matchID", -1)
				print("Lobby créé ! MatchID : ", match_id)
				lobby_cree.emit(match_id)
			else:
				print("Erreur création lobby : ", data.get("messageErreur", "Inconnue"))

		2:  # LEAVE_LOBBY
			if not erreur:
				print("Lobby quitté.")
				lobby_quitte.emit()
			else:
				print("Erreur quitter lobby : ", data.get("messageErreur", "Inconnue"))
			
		3: # JOIN_LOBBY
			if not erreur:
				var lobby_data = data
				Global.number_turn_max = data.get("numberTurn",-1)
				print("Lobby rejoint ! Joueurs : ", lobby_data)
				print(data.get("mapID", 0))
				var map_name = int(data.get("mapID", 0))
				if map_name == 0:
					Global.current_map_name = "Map1"
					print(Global.current_map_name)
				else:
					Global.current_map_name = "Map2"
					print(Global.current_map_name)

				lobby_rejoint.emit(lobby_data)

			else:
				print("Erreur rejoindre lobby : ", data.get("messageErreur", "Inconnue"))
		
		4: 
			if not erreur:
				print("Joueur ready : ", data)
				#A COMPLETER ET CREE HANDLE
			
		5: # START_GAME
			if not erreur:
				print("Partie démarrée : ", data)
				partie_demarree.emit(data)
			else:
				print("Erreur démarrage partie : ", data.get("messageErreur", "Inconnue"))


func _handle_game(subID: int, erreur: bool, data: Dictionary):
	if erreur:
		print("Erreur action jeu (subID=%d) : %s" % [subID, data.get("messageErreur", "Inconnue")])


func _handle_server_push(subID: int, data: Dictionary):
	match subID:
		1: # SNAPSHOT
			var state = data.get("state", {})
			print("Snapshot reçu.")
			snapshot_recu.emit(state)

		2: # EVENT
			var event_type = data.get("eventType", "")
			var payload = data.get("payload", {})
			_handle_event(event_type, payload)

		_:
			print("subID Server Push inconnu : ", subID)


func _handle_event(event_type: int, payload: Dictionary):
	match event_type:
		# --- Lobby ---
		#"LOBBY_PLAYER_JOINED"
		1:
			joueur_rejoint_lobby.emit(
				payload.get("clientID", -1), 
				payload.get("username", "Inconnu"), 
				payload.get("ready", false), 
				payload.get("classID", 0)
)
		#"LOBBY_PLAYER_LEFT"
		2:
			joueur_quitte_lobby.emit(payload.get("clientID", -1))

		#"GAME_STARTED"
		3:
			jeu_demarre.emit(payload)
			Global.number_turn = int(payload.get("nombre_tour",999))
			print("La partie commence")

		# --- Tour ---
		#"TURN_CHANGED"
		4:
			tour_change.emit(payload.get("currentClientID", -1))
			Global.number_turn = int(payload.get("nb_turn",0))
			
			
		#"END_TURN"
		10:
			fin_tour.emit(payload.get("clientID", -1))
		# --- Dés ---
		#"DICE_ROLLED"
		5:
			des_lances.emit(payload)

		# --- Propriétés ---
		#"PROPERTY_BOUGHT"
		6:
			propriete_achetee.emit(payload.get("clientID", -1), payload.get("propertyID", -1))

		#"HOUSE_BUILT"
		7:
			maison_construite.emit(payload)

		#"HOTEL_BUILT" #Implementer dans reseau
		"HOTEL_BUILT":
			hotel_construit.emit(payload)
		#"READY"
		12:
			joueur_ready.emit(payload.get("clientID", -1),payload.get("classID"))
		# --- Prison ---
		#"GOT_OUT_OF_JAIL"
		8:
			sorti_de_prison.emit(payload.get("clientID", -1))
			
		9: # USE_CARD
			carte_utilisee.emit(payload.get("clientID", -1), payload.get("cardID", -1))

		# --- Fin de partie ---
		13: # PLAYER_ELIMINATED
					var eliminated_ids = payload.get("clientID", [])
					
					# Puisque c'est toujours un tableau, on boucle directement
					for id in eliminated_ids:
						# On force la conversion en int au cas où le JSON envoie un float
						var cid = int(id)
						joueur_en_faillite.emit(cid)
						print("🔧 Signal Faillite émis pour le joueur : ", cid)
		#"GAME_ENDED"
		11:
			jeu_termine.emit(
				payload.get("winnerID",-1),
				payload.get("classement",[])
			)
			print("GameEnded")

		_:
			print("eventType inconnu : ", event_type)
