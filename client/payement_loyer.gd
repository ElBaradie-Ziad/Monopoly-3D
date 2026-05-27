extends Control

# ====================== RÉFÉRENCES UI ======================
@onready var joueur_label: Label = $Panel/MarginContainer/VBoxContainer/Joueur
@onready var montant_label: Label = $Panel/MarginContainer/VBoxContainer/Montant
@onready var name_prop_label: Label = $Panel/MarginContainer/VBoxContainer/NameProp

# ====================== INITIALISATION ======================

func setup_popup(player_name: String, case_id: int, montant: int) -> void:
	# 1. Récupération du nom de la propriété dans GameData
	# On suppose que GameData contient un dictionnaire nommé 'data' ou 'MAP'
	var prop_name = "Propriété inconnue"
	
	if GameData.PROPERTIES.has(case_id):
		prop_name = GameData.PROPERTIES[case_id].get("name", "Sans nom")
	else:
		push_warning("⚠️ Case ID " + str(case_id) + " introuvable dans GameData")

	# 2. Mise à jour des textes avec tes variables
	name_prop_label.text = prop_name
	joueur_label.text = "Cette propriété appartient a " + player_name
	montant_label.text = "En tant que visiteur, vous devez vous acquitter d'un loyer de " + str(montant) + " M."
	
# 3. Affichage du popup
	self.show()

	# --- NOUVEAU : Attente de 3 secondes puis fermeture ---
	# On crée un timer one-shot via l'arbre de scène
	await get_tree().create_timer(5.0).timeout
	
	# On cache le popup automatiquement
	self.hide()
