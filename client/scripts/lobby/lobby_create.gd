# CreateLobbyMenu.gd
extends Control

# Variables de sélection actuelles
var selected_tours: int = -1
var selected_money: int = 1500
var selected_map_id: int = 0

# Références aux TextureButtons (tes chemins exacts)
@onready var tours_buttons: Array[BaseButton] = [
	$MainPanel/Content/ToursSection/ToursContainer/btn_ilimite,
	$MainPanel/Content/ToursSection/ToursContainer/btn_20tours,
	$MainPanel/Content/ToursSection/ToursContainer/btn_30tours,
	$MainPanel/Content/ToursSection/ToursContainer/btn_40tours,
	$MainPanel/Content/ToursSection/ToursContainer/btn_50tours
]

@onready var money_buttons: Array[BaseButton] = [
	$MainPanel/Content/ArgentSection/ArgentsContainer/btn_1000M,
	$MainPanel/Content/ArgentSection/ArgentsContainer/btn_1500M,
	$MainPanel/Content/ArgentSection/ArgentsContainer/btn_2000M,
	$MainPanel/Content/ArgentSection/ArgentsContainer/btn_3000M
]

@onready var create_button: BaseButton = $MainPanel/Content/VBoxContainer/btn_create

func _ready() -> void:
	Global.lobby_players.clear()
	update_tours_selection(-1)
	update_money_selection(1500)
	
	# Connexion du signal du réseau
	if not Reseau.lobby_cree.is_connected(_on_lobby_cree):
		Reseau.lobby_cree.connect(_on_lobby_cree)


# ==================== FONCTIONS APPELÉES PAR LES SIGNAUX ====================
func _on_tours_button_pressed(tours: int) -> void:
	SoundManager.play_clique()
	update_tours_selection(tours)

func _on_money_button_pressed(amount: int) -> void:
	SoundManager.play_clique()
	update_money_selection(amount)

func _on_close_pressed() -> void:
	queue_free()

# ==================== MISE À JOUR VISUELLE TOURS ====================
func update_tours_selection(tours: int) -> void:
	selected_tours = tours
	
	_reset_all_tours()
	
	for btn in tours_buttons:
		if (tours == -1 and btn.name == "ilimite_button") or \
		   (tours != -1 and btn.name.begins_with(str(tours) + "tours")):
			btn.get_parent().set_selected(true) # On dit au parent de s'allumer
			break

# ==================== MISE À JOUR VISUELLE ARGENT ====================
func update_money_selection(amount: int) -> void:
	selected_money = amount
	
	_reset_all_money()
	
	for btn in money_buttons:
		if btn.name.begins_with(str(amount)):
			btn.get_parent().set_selected(true) # On dit au parent de s'allumer
			break

# ==================== FONCTIONS HELPER ====================
func _reset_all_tours() -> void:
	for btn in tours_buttons:
		if btn.get_parent().has_method("set_selected"):
			btn.get_parent().set_selected(false)

func _reset_all_money() -> void:
	for btn in money_buttons:
		if btn.get_parent().has_method("set_selected"):
			btn.get_parent().set_selected(false)

# ==================== ENVOI DE LA REQUÊTE ====================
func _on_create_lobby_pressed() -> void:
	# number_turn est déjà un int (-1 ou le nombre de tours)
	SoundManager.play_clique()
	var number_turn = selected_tours
	print(selected_money)
	print(selected_tours)
	Global.argent_depart = selected_money
	Global.number_turn_max = selected_tours
	Global.is_host = true
	
	var request_data = {
		"mainID": 2,
		"subID": 1,
		"clientID": Global.my_client_id,
		"data": {
			"mapID": id_map,
			"numberTurn": number_turn,
			"moneyStart": selected_money,
			"username": Global.my_username,
		}
	}
	
	Reseau.send_data(request_data)
	
	

func _on_leave_pressed() -> void:
	SoundManager.play_clique_negatif()
	$".".hide()

# ==================== RÉCEPTION DU SIGNAL ====================
func _on_lobby_cree(match_id: int) -> void:
	Global.current_match_id = match_id
# On initialise la liste avec le créateur du lobby
	if Global.lobby_players.is_empty():
		Global.lobby_players = [{
			"clientID": Global.my_client_id,
			"username": Global.my_username
		}]
	
	var err = get_tree().change_scene_to_file("res://scenes/Menu/LobbyScreen.tscn")
	if err != OK:
		push_error("❌ Erreur changement de scène : " + str(err))


func _on_btn_30_tours_pressed(extra_arg_0: int) -> void:
	pass # Replace with function body.

var id_map: int = 0

@onready var map_preview: TextureRect = $MainPanel/Content/MapSection/mapchoice/TextureRect/MapPreview

# Dictionnaire avec les infos des maps (facile à étendre plus tard)
var maps = {
	0: {
		"name": "Map1",
		"texture": preload("res://assets/models/board/Map1.png")
	},
	1: {
		"name": "Map2",
		"texture": preload("res://assets/models/board/Map2.png")
	}
}

func _on_fleche_pressed() -> void:
	id_map = (id_map + 1) % maps.size()   # Cycle automatique entre 0 et 1
	map_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	map_preview.ignore_texture_size = true
	var current = maps[id_map]
	
	# Mise à jour de l'image
	map_preview.texture = current.texture
	
	# Mise à jour de la variable globale
	Global.current_map_name = current.name
	
	# Optionnel : petit feedback visuel
	map_preview.scale = Vector2(1.05, 1.05)
	var tween = create_tween()
	tween.tween_property(map_preview, "scale", Vector2(1, 1), 0.2)
	
	print("Map sélectionnée : ", current.name)
