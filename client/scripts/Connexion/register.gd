extends Control

@onready var username_input = %inputPseudo
@onready var password_input = %inputPassword
@onready var error_label: Label = get_node_or_null("../../Error")

func _ready():
	Reseau.register_echec.connect(_on_register_echec)
	if error_label:
		error_label.text= ""

func _on_btn_create_account_pressed():
	SoundManager.play_clique()
	var username = username_input.text.strip_edges()
	var password = password_input.text 

	if username == "":
		print("Erreur locale : Le pseudo est vide !")
		error_label.text= "NOM D'UTILISATEUR VIDE"
		SoundManager.play_clique_negatif()
		# if error_label: error_label.text = "Le pseudo est obligatoire"
		return
	if password == "":
		error_label.text= "MOT DE PASSE VIDE"
		SoundManager.play_clique_negatif()
		
	Global.my_username = username

	# 2. Construction du JSON selon le protocole #NET-01 (MainID 1, SubID 3)
	var request_data = {
		"mainID": 1,
		"subID": 3,
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


	
	
func _on_register_echec():
	error_label.text= "NOM D UTILISATEUR DÉJÀ UTILISÉ"
	SoundManager.play_clique_negatif()


func _on_join_button_pressed() -> void:
	pass # Replace with function body.
