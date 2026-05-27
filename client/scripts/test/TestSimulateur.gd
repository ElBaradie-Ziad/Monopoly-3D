extends Node

# TestSimulator.gd

func _ready():
	return
	await get_tree().process_frame
	await get_tree().create_timer(11.0).timeout
	await _init_client_id()
	await run_scenario_carte_prison()
	#mettre une des fonctions run scenario à la place du return pour test

# ─── Init ───────────────────────────────────────────────────

func _init_client_id():
	Global.my_client_id = 1
	Global.current_match_id = 42
	Global.joueurs = [1, 2]
	Global.lobby_players = [
		{"clientID": 1, "username": "TestJoueur"},
		{"clientID": 2, "username": "Joueur2"}
	]
	await _simulate({
		"mainID": 0,
		"subID": 0,
		"erreur": false,
		"data": {"clientID": 1}
	})
	var game_scene = get_tree().get_root().get_node("Main")
	game_scene._on_jeu_demarre()
	var board = game_scene.board
	for id in board._pawns.keys():
		board._pawns[id].queue_free()
	board._pawns.clear()
	board._pawn_indices.clear()
	board._spawn_all_pawns()
	await get_tree().create_timer(0.5).timeout

# ─── Simulate ───────────────────────────────────────────────

func _simulate(msg: Dictionary):
	var json_string = JSON.stringify(msg)
	var packed = json_string.to_utf8_buffer()
	Reseau._on_data_received(packed)
	await get_tree().create_timer(0.3).timeout

# ─── Helpers ────────────────────────────────────────────────

func _push_event(event_type: int, payload: Dictionary) -> Dictionary:
	return {
		"mainID": 4,
		"subID": 2,
		"erreur": false,
		"data": {
			"eventType": event_type,
			"payload": payload
		}
	}
func _house_built_event(client_id: int, prop_id: int, total: int) -> Dictionary:
	return {
		"mainID": 4,
		"subID": 2,
		"erreur": false,
		"data": {
			"eventType": 7, # L'ID 7 correspond à HOUSE_BUILT dans ton Reseau.gd
			"payload": {
				"clientID": client_id,
				"propertyID": prop_id,
				"totalHouses": total
			}
		}
	}

func _tour_change(client_id: int) -> Dictionary:
	return _push_event(4, {"currentClientID": client_id})

func _dice_rolled(client_id: int, d1: int, d2: int, card: int = -1) -> Dictionary:
	return _push_event(5, {"clientID": client_id, "dice1": d1, "dice2": d2, "card": card})

func _end_turn(client_id: int) -> Dictionary:
	return _push_event(10, {"clientID": client_id})

func _property_bought(client_id: int, property_id: int) -> Dictionary:
	return _push_event(6, {"clientID": client_id, "propertyID": property_id})

func _got_out_of_jail(client_id: int) -> Dictionary:
	return _push_event(8, {"clientID": client_id})

func _game_ended(winner_id: int) -> Dictionary:
	return _push_event(11, {"winnerID": winner_id})

# ─── Scénarios ──────────────────────────────────────────────

func run_scenario_tour_normal():
	print("=== SCÉNARIO : Tour normal ===")
	var me = Global.my_client_id

	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout

	await _simulate(_dice_rolled(me, 3, 4, 104))
	await get_tree().create_timer(6.0).timeout

	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout

	#await _simulate(_tour_change(me))
	#await get_tree().create_timer(2.5).timeout
	print("=== FIN scénario tour normal ===")

func run_scenario_achat_propriete():
	print("=== SCÉNARIO : Achat propriété ===")
	var me = Global.my_client_id

	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout

	# Case 1 = Mediterranean Avenue, non achetée → popup achat
	Global.positions_joueurs[me] = 0
	await _simulate(_dice_rolled(me, 1, 0))
	await get_tree().create_timer(6.0).timeout

	await _simulate(_property_bought(me, 1))
	await get_tree().create_timer(1.0).timeout

	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout
	print("=== FIN scénario achat propriété ===")

func run_scenario_double():
	print("=== SCÉNARIO : Double (rejoue) ===")
	var me = Global.my_client_id

	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout

	await _simulate(_dice_rolled(me, 3, 3))
	await get_tree().create_timer(10.0).timeout

	await _simulate(_dice_rolled(me, 2, 4))
	await get_tree().create_timer(6.0).timeout

	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout
	print("=== FIN scénario double ===")

func run_scenario_prison():
	print("=== SCÉNARIO : Prison ===")
	var me = Global.my_client_id

	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout

	# Forcer position pour tomber sur la case 30 (allez en prison)
	Global.positions_joueurs[me] = 23
	await _simulate(_dice_rolled(me, 4, 3))
	await get_tree().create_timer(6.0).timeout

	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout

	# Tour 1 en prison — popup doit s'afficher, pas de double
	print("-- Tour 1 en prison --")
	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout

	await _simulate(_dice_rolled(me, 2, 5))
	await get_tree().create_timer(6.0).timeout

	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout

	# Tour 2 en prison — double, sort de prison
	print("-- Tour 2 en prison, double --")
	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout

	await _simulate(_dice_rolled(me, 3, 3))
	await get_tree().create_timer(1.0).timeout

	await _simulate(_got_out_of_jail(me))
	await get_tree().create_timer(6.0).timeout

	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout
	print("=== FIN scénario prison ===")

func run_scenario_passage_depart():
	print("=== SCÉNARIO : Passage case départ ===")
	var me = Global.my_client_id

	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout

	Global.positions_joueurs[me] = 36
	await _simulate(_dice_rolled(me, 5, 4))
	await get_tree().create_timer(6.0).timeout

	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout
	print("=== FIN scénario passage départ ===")

func run_scenario_carte_chance():
	print("=== SCÉNARIO : Carte chance ===")
	var me = Global.my_client_id

	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout

	# Case 7 = carte chance
	Global.positions_joueurs[me] = 0
	await _simulate(_dice_rolled(me, 3, 4, 102))
	await get_tree().create_timer(6.0).timeout

	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout
	print("=== FIN scénario carte chance ===")

func run_scenario_loyer():
	print("=== SCÉNARIO : Loyer ===")
	var me = Global.my_client_id
	var autre = 2

	# Simuler que joueur 2 possède la case 3
	Global.proprietes_joueurs[3] = autre
	Global.positions_joueurs[me] = 0

	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout

	await _simulate(_dice_rolled(me, 1, 2))  # tombe case 3, propriété de autre
	await get_tree().create_timer(6.0).timeout

	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout
	print("=== FIN scénario loyer ===")
	
func run_scenario_carte_prison():
	print("=== SCÉNARIO : Carte sortie de prison ===")
	var me = Global.my_client_id

	# Simuler réception d'une carte "sortie de prison" via communauté
	Global.cartes_prison[me] = 1

	# Tomber en prison
	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout

	Global.positions_joueurs[me] = 23
	await _simulate(_dice_rolled(me, 4, 3))  # tombe case 30
	await get_tree().create_timer(6.0).timeout

	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout

	# Tour suivant en prison — bouton carte doit être visible
	print("-- Tour en prison, carte disponible --")
	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout

	# Simuler utilisation de la carte
	await _simulate(_push_event(9, {"clientID": me, "cardID": 1}))
	await get_tree().create_timer(1.0).timeout

	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout
	print("=== FIN scénario carte prison ===")
	
func run_scenario_deux_joueurs():
	print("=== SCÉNARIO : Deux joueurs ===")
	var me = Global.my_client_id
	var autre = 2

	# Mon tour
	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout
	await _simulate(_dice_rolled(me, 3, 4,102))
	await get_tree().create_timer(6.0).timeout
	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout

	# Tour du joueur 2
	print("-- Tour joueur 2 --")
	await _simulate(_tour_change(autre))
	await get_tree().create_timer(2.5).timeout
	await _simulate(_dice_rolled(autre, 2, 5,102))
	await get_tree().create_timer(6.0).timeout
	await _simulate(_end_turn(autre))
	await get_tree().create_timer(1.0).timeout

	# Mon tour à nouveau
	print("-- Mon tour à nouveau --")
	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout
	await _simulate(_dice_rolled(me, 1, 2))
	await get_tree().create_timer(6.0).timeout
	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout
	print("=== FIN scénario deux joueurs ===")

func run_scenario_prison_deux_joueurs():
	print("=== SCÉNARIO : Prison deux joueurs ===")
	var me = Global.my_client_id
	var autre = 2

	# Mon tour — je tombe en prison
	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout
	Global.positions_joueurs[me] = 23
	await _simulate(_dice_rolled(me, 4, 3))  # tombe case 30
	await get_tree().create_timer(10.0).timeout
	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout

	# Tour joueur 2 — joue normalement pendant que je suis en prison
	print("-- Tour joueur 2 --")
	await _simulate(_tour_change(autre))
	await get_tree().create_timer(2.5).timeout
	await _simulate(_dice_rolled(autre, 3, 4))
	await get_tree().create_timer(6.0).timeout
	await _simulate(_end_turn(autre))
	await get_tree().create_timer(1.0).timeout

	# Mon tour en prison — popup doit s'afficher, pas de double
	print("-- Mon tour 1 en prison --")
	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout
	await _simulate(_dice_rolled(me, 2, 5))
	await get_tree().create_timer(6.0).timeout
	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout

	# Tour joueur 2
	print("-- Tour joueur 2 --")
	await _simulate(_tour_change(autre))
	await get_tree().create_timer(2.5).timeout
	await _simulate(_dice_rolled(autre, 1, 3))
	await get_tree().create_timer(6.0).timeout
	await _simulate(_end_turn(autre))
	await get_tree().create_timer(1.0).timeout

	# Mon tour en prison — double, sort de prison
	print("-- Mon tour 2 en prison, double --")
	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout
	await _simulate(_dice_rolled(me, 3, 3))
	await get_tree().create_timer(1.0).timeout
	await _simulate(_got_out_of_jail(me))
	await get_tree().create_timer(6.0).timeout
	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout
	print("=== FIN scénario prison deux joueurs ===")

func run_scenario_prison_adversaire():
	print("=== SCÉNARIO : Prison adversaire ===")
	var me = Global.my_client_id
	var autre = 2

	# Mon tour normal
	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout
	await _simulate(_dice_rolled(me, 3, 4))
	await get_tree().create_timer(6.0).timeout
	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout

	# Tour joueur 2 — tombe en prison
	print("-- Tour joueur 2, va en prison --")
	await _simulate(_tour_change(autre))
	await get_tree().create_timer(2.5).timeout
	Global.positions_joueurs[autre] = 23
	await _simulate(_dice_rolled(autre, 4, 3))  # tombe case 30
	await get_tree().create_timer(10.0).timeout
	await _simulate(_end_turn(autre))
	await get_tree().create_timer(1.0).timeout

	# Mon tour
	print("-- Mon tour --")
	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout
	await _simulate(_dice_rolled(me, 2, 3))
	await get_tree().create_timer(6.0).timeout
	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout

	# Tour joueur 2 en prison — pas de double
	print("-- Tour joueur 2 en prison, pas de double --")
	await _simulate(_tour_change(autre))
	await get_tree().create_timer(2.5).timeout
	await _simulate(_dice_rolled(autre, 2, 5))
	await get_tree().create_timer(6.0).timeout
	await _simulate(_end_turn(autre))
	await get_tree().create_timer(1.0).timeout

	# Mon tour
	print("-- Mon tour --")
	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout
	await _simulate(_dice_rolled(me, 1, 4))
	await get_tree().create_timer(6.0).timeout
	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout

	# Tour joueur 2 en prison — double, sort
	print("-- Tour joueur 2 en prison, double --")
	await _simulate(_tour_change(autre))
	await get_tree().create_timer(2.5).timeout
	await _simulate(_dice_rolled(autre, 3, 3))
	await get_tree().create_timer(1.0).timeout
	await _simulate(_got_out_of_jail(autre))
	await get_tree().create_timer(6.0).timeout
	await _simulate(_end_turn(autre))
	await get_tree().create_timer(1.0).timeout
	print("=== FIN scénario prison adversaire ===")

func run_scenario_construction_complete():
	print("=== DÉBUT : Scénario Construction même case ===")
	var me = Global.my_client_id

	# --- TOUR 1 : Arrivée et Achat ---
	await _simulate(_tour_change(me))
	Global.positions_joueurs[me] = 0
	await _simulate(_dice_rolled(me, 1, 0)) # On avance sur la case 1
	await get_tree().create_timer(4.0).timeout

	# On simule que l'achat est validé par le serveur
	await _simulate(_property_bought(me, 1))
	# Important : On met à jour l'état local pour que le jeu sache qu'on est proprio
	Global.proprietes_joueurs[1] = me 
	
	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.5).timeout

	# --- TOUR 2 : On reste sur place et on construit ---
	print("--- Nouveau tour : On construit sur la case 1 ---")
	await _simulate(_tour_change(me))
	
	# On simule un lancer qui nous laisse sur place
	await _simulate(_dice_rolled(me, 0, 0))
	Global.positions_joueurs[me] = 1 
	await get_tree().create_timer(1.0).timeout

	# ACTION : On simule l'arrivée du message "3 maisons construites"
	# Cela va déclencher _on_maison_construite dans Main.gd
	print("Simulation : Réception serveur -> 3 maisons au total")
	await _simulate(_house_built_event(me, 1, 3))
	
	await get_tree().create_timer(3.0).timeout

	# ACTION : On simule le passage à l'hôtel (5 unités)
	print("Simulation : Réception serveur -> Passage à l'Hôtel")
	await _simulate(_house_built_event(me, 1, 5))

	await get_tree().create_timer(3.0).timeout
	await _simulate(_end_turn(me))
	print("=== FIN : Scénario Construction ===")
	
func run_scenario_construction_test_ui():
	print("=== DEBUG UI MAISONS START ===")
	var me = Global.my_client_id
	var game_scene = get_tree().get_root().get_node("Main")

	# --- TOUR 1 : ACHAT ---
	await _simulate(_tour_change(me))
	Global.positions_joueurs[me] = 0
	# On simule un dé de 1 pour aller sur la case 1
	await _simulate(_dice_rolled(me, 1, 0)) 
	
	# ATTENTION : On attend que le pion finisse de bouger
	await get_tree().create_timer(4.0).timeout 
	
	await _simulate(_property_bought(me, 1))
	Global.proprietes_joueurs[1] = me
	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout

	# --- TOUR 2 : TEST POPUP ---
	await _simulate(_tour_change(me))
	# On simule un lancer de 0 pour rester sur la case 1
	await _simulate(_dice_rolled(me, 0, 0))
	await get_tree().create_timer(1.0).timeout

	print("FORCE OUVERTURE POPUP")
	game_scene.ui.show_popup_maison(1)
	
	# Le simulateur s'arrête ici tant que tu n'as pas cliqué sur "Acheter"
	await game_scene.ui.popups.achat_maison.visibility_changed
	
	print("CLIC DÉTECTÉ - Envoi construction au manager...")
	# On simule la réponse du serveur (ID 7 = HOUSE_BUILT)
	# On met 4 maisons pour bien les voir
	await _simulate(_house_built_event(me, 1, 4))
	
	await get_tree().create_timer(2.0).timeout
	await _simulate(_end_turn(me))
	print("=== DEBUG UI MAISONS END ===")
	
func run_scenario_passage_go_puis_tax():
	print("=== SCÉNARIO : Passage Go + Taxe ===")
	var me = Global.my_client_id

	await _simulate(_tour_change(me))
	await get_tree().create_timer(2.5).timeout

	Global.positions_joueurs[me] = 38
	await _simulate(_dice_rolled(me, 3, 3))  # 38 + 6 = 44 -> case 4 avec passage Go
	await get_tree().create_timer(6.0).timeout

	await _simulate(_end_turn(me))
	await get_tree().create_timer(1.0).timeout
	print("=== FIN scénario passage Go + Taxe ===")
	
