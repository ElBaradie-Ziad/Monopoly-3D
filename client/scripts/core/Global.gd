extends Node

# --- Infos Joueur ---
# Id donné par le server après le login
var my_client_id : int = -1

# Pseudo du joueur
var my_username : String = ""

# --- Infos Session ---
# L'ID de la partie actuelle reçu après create lobby ou join lobby
var current_match_id : int = -1

var joueurs: Array = [] #Liste des client ID à récup dans le lobby
var lobby_players: Array = []
# Index de couleur permanent par joueur (jamais modifié après le début de partie)
var player_color_index : Dictionary = {}  # { client_id: int }


#gestion classe
var select_classe: int
var classe1: Array = []
var classe2: Array = []
var classe3: Array = []

var number_turn: int = 999
var number_turn_max: int = 999
var current_map_name: String = "Map1" # Valeur par défaut pour éviter les crashs
var START_BONUS: int = 1500
var argent_depart : int = 0
var loyer_go: int = 200

var is_host : bool = false

var positions_joueurs := {}  # { client_id: position }
# À initialiser au SNAPSHOT ou au GAME_STARTED

var proprietes_joueurs: Dictionary = {}  # { property_id: client_id }
var maisons_proprietes: Dictionary = {} #  { property_id: int } # 0-4 maisons, 5 = hotel
var etat_prison: Dictionary = {} # {client_id : {"in_prison":bool, "tours_restants":int} 
var cartes_prison: Dictionary = {} # {client_id : card_id}

var current_client_id: int
var classement_final: Array = []
var pion_animation = 0
signal request_camera_global_view
signal request_camera_pion_view
var is_global_view: bool = true

func _reset():
	joueurs.clear()
	lobby_players.clear()
	player_color_index.clear()
	select_classe = 0
	classe1.clear()
	classe2.clear()
	classe3.clear()
	is_host = false
	positions_joueurs.clear()
	proprietes_joueurs.clear()
	maisons_proprietes.clear()
	etat_prison.clear()
	cartes_prison.clear()
	classement_final.clear()
	loyer_total_percu.clear()
	nb_passages_prison.clear()
	current_client_id = -1
	
# ── Statistiques de fin de partie ─────────────────────────────────────────────
var loyer_total_percu  : Dictionary = {}   # { client_id: int }  loyer encaissé
var nb_passages_prison : Dictionary = {}   # { client_id: int }  fois envoyé en prison

func reset_stats() -> void:
	loyer_total_percu.clear()
	nb_passages_prison.clear()

func add_loyer(client_id: int, montant: int) -> void:
	loyer_total_percu[client_id] = loyer_total_percu.get(client_id, 0) + montant

func add_prison(client_id: int) -> void:
	nb_passages_prison[client_id] = nb_passages_prison.get(client_id, 0) + 1
