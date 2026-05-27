extends Control

@onready var username_input = %inputPseudo
@onready var password_input = %inputPassword
@onready var error_label: Label = get_node_or_null("../../Error")
func _ready():
	Reseau.login_reussi.connect(_on_login_confirme)
	Reseau.login_echec.connect(_on_login_echec)
	Reseau.register_reussi.connect(_on_join_button_pressed)

	if error_label:
		error_label.text = ""
	





func _on_join_button_pressed():
	var username = username_input.text.strip_edges()
	var password = password_input.text 
	SoundManager.play_clique()
	Global.my_username = username
	if username == "":
		error_label.text= "NOM D'UTILISATEUR VIDE"
		SoundManager.play_clique_negatif()
		print("Erreur locale : Le pseudo est vide !")
		# if error_label: error_label.text = "Le pseudo est obligatoire"
	if password == "":
		error_label.text= "MOT DE PASSE VIDE"
		SoundManager.play_clique_negatif()
		return
		
	# 2. Construction du JSON selon le protocole #NET-01 (MainID 1, SubID 1)
	var request_data = {
		"mainID": 1,
		"subID": 1,
		"clientID": Global.my_client_id,
		"data": {
			"username": username,
			"password": password
		}
	}
	
	#test de debug
	print("JSON prêt à l'envoi : ", JSON.stringify(request_data))
	# 3. Envoi via le Singleton Reseau
	Reseau.send_data(request_data)
	
	
	

func _on_login_confirme():
	print("Mon ID : ", Global.my_client_id)
	var err = get_tree().change_scene_to_file("res://main_menu_v2.tscn")
	if err != OK:
		push_error("Erreur changement de scène : " + str(err))
	

func _on_login_echec():
	error_label.text= "NOM D'UTILISATEUR OU MOT DE PASSE INVALIDE"
	SoundManager.play_clique_negatif()


func _on_btn_create_account_pressed() -> void:
	pass # Replace with function body.


func _on_pressed() -> void:
	pass # Replace with function body.
