# BuyPropertyPopup.gd
# À attacher sur le nœud racine : BuyPropertyPopup (Panel)

extends Panel

# ====================== RÉFÉRENCES ======================
# Propriétés classiques
@onready var panel_prop: Panel = $BuyPropertyPopup
@onready var banderole_color_prop: ColorRect = $Banderole_color

@onready var nom_label_prop: Label = $BuyPropertyPopup/MarginContainer/VBoxContainer/Header/Nom
@onready var buy_price_label_prop: Label = $BuyPropertyPopup/MarginContainer/VBoxContainer/PriceBlock/BuyPrice

@onready var price1_label_prop: Label = $BuyPropertyPopup/MarginContainer/VBoxContainer/RentTable/MarginContainer/Hbox/GridContainer/Price1
@onready var price2_label_prop: Label = $BuyPropertyPopup/MarginContainer/VBoxContainer/RentTable/MarginContainer/Hbox/GridContainer/Price2
@onready var price3_label_prop: Label = $BuyPropertyPopup/MarginContainer/VBoxContainer/RentTable/MarginContainer/Hbox/GridContainer/Price3
@onready var price4_label_prop: Label = $BuyPropertyPopup/MarginContainer/VBoxContainer/RentTable/MarginContainer/Hbox/GridContainer/Price4
@onready var price5_label_prop: Label = $BuyPropertyPopup/MarginContainer/VBoxContainer/RentTable/MarginContainer/Hbox/GridContainer/Price5
@onready var price6_label_prop: Label = $BuyPropertyPopup/MarginContainer/VBoxContainer/RentTable/MarginContainer/Hbox/GridContainer/Price6

@onready var house_price_label_prop: Label = $BuyPropertyPopup/MarginContainer/VBoxContainer/HouseHotelPrice/HousePrice
@onready var hotel_price_label_prop: Label = $BuyPropertyPopup/MarginContainer/VBoxContainer/HouseHotelPrice/HotelPrice

# Gares
@onready var panel_gare: Panel = $BuyGarePopup
@onready var nom_label_gare: Label = $BuyGarePopup/MarginContainer/VBoxContainer/Header/Nom
@onready var buy_price_label_gare: Label = $BuyGarePopup/MarginContainer/VBoxContainer/PriceBlock/BuyPrice

@onready var price1_label_gare: Label = $BuyGarePopup/MarginContainer/VBoxContainer/RentTable/MarginContainer/Hbox/GridContainer/Price1
@onready var price2_label_gare: Label = $BuyGarePopup/MarginContainer/VBoxContainer/RentTable/MarginContainer/Hbox/GridContainer/Price2
@onready var price3_label_gare: Label = $BuyGarePopup/MarginContainer/VBoxContainer/RentTable/MarginContainer/Hbox/GridContainer/Price3
@onready var price4_label_gare: Label = $BuyGarePopup/MarginContainer/VBoxContainer/RentTable/MarginContainer/Hbox/GridContainer/Price4


#Compagnies: 
@onready var panel_elec: Panel = $BuyCompagnieElecPopup
@onready var panel_eau: Panel = $BuyCompagnieEauPopup

signal choice_made(accepted: bool)

func _ready() -> void:
	hide()                    # On cache au démarrage
	
	# === TEST AUTOMATIQUE - Décommente celui que tu veux tester ===
	#show_property(5)     # Propriété classique (Rue de la Paix)
	#show_property(12)        # Gare Montparnasse (pour tester les gares)

func _on_btn_acheter_pressed():
	SoundManager.play_buy()
	choice_made.emit(true)
	hide()

func _on_btn_deny_pressed():
	SoundManager.play_dontbuy()
	choice_made.emit(false)
	hide()

func show_property(case_id: int) -> void:
	
	var property = GameData.PROPERTIES.get(case_id)
	if property == null:
		push_error("BuyPropertyPopup: Case " + str(case_id) + " non trouvée dans GameData")
		return
	
	# Masquer les deux panels
	if panel_prop:
		panel_prop.visible = false
	if panel_gare:
		panel_gare.visible = false
	if panel_elec:
		panel_elec.visible = false
	if panel_eau:
		panel_eau.visible = false
		


		
	if property.type == "property":
		panel_prop.visible = true
		
		banderole_color_prop.modulate = property.color
		nom_label_prop.text = property.name.to_upper()
		buy_price_label_prop.text = "PRIX : " + str(property.price) + " M"
		
		price1_label_prop.text = str(property.rent_base) + " M"
		price2_label_prop.text = str(property.rent_1h) + " M"
		price3_label_prop.text = str(property.rent_2h) + " M"
		price4_label_prop.text = str(property.rent_3h) + " M"
		price5_label_prop.text = str(property.rent_4h) + " M"
		price6_label_prop.text = str(property.rent_hotel) + " M"
		
		house_price_label_prop.text = "Maison : " + str(property.house_cost) + " M"
		hotel_price_label_prop.text = "Hôtel : " + str(property.hotel_cost) + " M"

	elif property.type == "station":
		panel_gare.visible = true
		
		nom_label_gare.text = property.name.to_upper()
		buy_price_label_gare.text = "PRIX : " + str(property.price) + " M"
		
		price1_label_gare.text = str(property.rent_base) + " M"
		price2_label_gare.text = str(property.rent_1station) + " M"
		price3_label_gare.text = str(property.rent_2stations) + " M"
		price4_label_gare.text = str(property.rent_3stations) + " M"
		
		# Masquer les lignes inutiles pour les gares
		var grid = $BuyGarePopup/MarginContainer/VBoxContainer/RentTable/MarginContainer/Hbox/GridContainer
		if grid and grid.has_node("Price5"):
			grid.get_node("Price5").visible = false
		if grid and grid.has_node("Price6"):
			grid.get_node("Price6").visible = false
			
	elif case_id == 12:
		panel_eau.visible = true
	elif case_id == 28:
		panel_elec.visible = true		
	else:
		push_error("BuyPropertyPopup: Type non supporté : " + property.type)
		return
	
	# On rend le popup visible
	show()
