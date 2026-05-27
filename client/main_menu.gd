extends Control
@onready var profile_pseudo: Label = $MainLayout/LeftPanel/MarginContainer/VBoxContainer/HBoxContainer/Profile/pseudo
var animation_player: AnimationPlayer = null
var cinematic_camera: Camera3D = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# Recherche des nodes après le chargement de la map
	SoundManager.play_music("music", SoundManager.lvl_music_settings)

	animation_player = find_child("AnimationPlayer2", true, false)
	cinematic_camera = find_child("Camera3D3", true, false)
	$MainLayout/CenterContent/CreateLobbyMenu.hide()
	$MainLayout/CenterContent/LobbyJoin.hide()
	profile_pseudo.text = Global.my_username if not Global.my_username.is_empty() else "JoueurX"
	if animation_player and cinematic_camera:
		print("🎬 AnimationPlayer et Camera trouvés → Lancement de l'animation...")
		cinematic_camera.make_current()
		
		# Remplace "Camera_Open" par le nom EXACT de ton animation
		animation_player.play("Main_menu_turn")
		
		await animation_player.animation_finished
		
		print("✅ Animation cinématique terminée")




func _on_create_button_pressed() -> void:
	SoundManager.play_clique2()
	$MainLayout/CenterContent/LobbyJoin.hide()
	$MainLayout/CenterContent/CreateLobbyMenu.show()
	

func _on_join_button_pressed() -> void:
	SoundManager.play_clique()
	$MainLayout/CenterContent/CreateLobbyMenu.hide()
	$MainLayout/CenterContent/LobbyJoin.show()


func _on_leave_pressed()-> void:
	SoundManager.play_clique()
	$MainLayout/CenterContent/Guide.hide()
	$MainLayout/CenterContent/Settings.hide()
	$MainLayout/CenterContent/QuitterPannel.show()


func _on_settings_pressed()-> void:
	SoundManager.play_clique()
	$MainLayout/CenterContent/Guide.hide()
	$MainLayout/CenterContent/QuitterPannel.hide()
	$MainLayout/CenterContent/Settings.show()


func on_info_pressed()->void:
	SoundManager.play_clique()
	$MainLayout/CenterContent/Settings.hide()
	$MainLayout/CenterContent/QuitterPannel.hide()

	$MainLayout/CenterContent/Guide.show()
	
