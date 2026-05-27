extends Control

@onready var pseudo_label: Label = $MainLayout/ColorRect/LeftPanel/MarginContainer/VBoxContainer/Profile/VBoxContainer/pseudo
@onready var create_game_btn: Button = $MainLayout/ColorRect/LeftPanel/MarginContainer/VBoxContainer/CreateGameButton
@onready var join_game_btn: Button = $MainLayout/ColorRect/LeftPanel/MarginContainer/VBoxContainer/JoinGameButton
@onready var join_panel: VBoxContainer = $MainLayout/CenterContent/JoinPanel
@onready var match_id_input: LineEdit = $MainLayout/CenterContent/JoinPanel/MatchIDInput
@onready var confirm_btn: Button = $MainLayout/CenterContent/JoinPanel/ConfirmButton
@onready var error_label: Label = $MainLayout/CenterContent/JoinPanel/ErrorLabel


func _ready() -> void:
	Global._reset()
	if Global.my_username != "":
		pseudo_label.text = Global.my_username

	Reseau.lobby_cree.connect(_on_lobby_created)
	Reseau.lobby_rejoint.connect(_on_lobby_joined)

	create_game_btn.pressed.connect(_on_create_game_pressed)
	join_game_btn.pressed.connect(_on_join_game_pressed)
	confirm_btn.pressed.connect(_on_confirm_join_pressed)


	

	return
# --- CREER UNE PARTIE ---

func _on_create_game_pressed() -> void:
	create_game_btn.disabled = true
	Global.is_host = true
	Reseau.send_data({
		"mainID": 2,
		"subID": 1,
		"data": {}
	})


func _on_lobby_created(match_id: int) -> void:
	Global.current_match_id = match_id
	get_tree().change_scene_to_file("res://scenes/lobby/create_lobby.tscn")


# --- REJOINDRE UNE PARTIE ---

func _on_join_game_pressed() -> void:
	join_panel.visible = not join_panel.visible
	if join_panel.visible:
		match_id_input.grab_focus()
	error_label.visible = false


func _on_confirm_join_pressed() -> void:
	var raw := match_id_input.text.strip_edges()
	if raw == "" or not raw.is_valid_int():
		error_label.text = "ID invalide, entrez un nombre."
		error_label.visible = true
		return

	error_label.visible = false
	confirm_btn.disabled = true
	Reseau.send_data({
		"mainID": 2,
		"subID": 2,
		"data": {"MatchID": int(raw)}
	})


func _on_lobby_joined(_players: Array) -> void:
	get_tree().change_scene_to_file("res://scenes/lobby/join_lobby.tscn")
