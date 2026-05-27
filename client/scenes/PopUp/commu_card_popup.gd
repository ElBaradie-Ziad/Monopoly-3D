# CommunityCardPopup.gd
# À attacher sur le nœud racine : CommunityCardPopup (Control)

extends Control

@onready var card_pivot: Control = $CardPivot
@onready var card_back: Panel = $CardPivot/CardBack
@onready var card_front: Panel = $CardPivot/CardFront
@onready var title_label: Label = $CardPivot/CardFront/FrontBorder/MarginContainer/VBoxContainer/TitleLabel
@onready var message_label: Label = $CardPivot/CardFront/FrontBorder/MarginContainer/VBoxContainer/MessageLabel

# ────────────────────────────────────────
# Fonction principale : on passe uniquement l'ID de la carte Communauté
func show_card(card_id: int) -> void:
	var card = GameData.COMMUNITY_CHEST_CARDS.get(card_id)
	
	if card == null:
		push_error("ChanceCardPopUp: Carte " + str(card_id) + " non trouvée")
		hide()
		return
	
	# Mise à jour du texte
	title_label.text = "CARTE COMMUNAUTÉ"
	message_label.text = card.text
	
	# Optionnel : changer la couleur du titre selon le type
	if card.type == "positive":
		title_label.modulate = Color(0.0, 0.902, 0.2, 1.0)   # jaune doré
	elif card.type == "negative":
		title_label.modulate = Color(0.9, 0.2, 0.2)   # rouge
	else:
		title_label.modulate = Color(1.0, 1.0, 1.0)   # blanc par défaut

	# Animation d'apparition
	modulate.a = 0.0
	scale = Vector2(0.1, 0.1)
	card_back.visible = true
	card_front.visible = false
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	SoundManager.play_carte_flip()
	await get_tree().create_timer(0.4).timeout
	
	# Flip (retournement de la carte)
	var flip = create_tween()
	flip.tween_property(card_pivot, "scale:x", -1.0, 0.35).set_trans(Tween.TRANS_SINE)
	
	flip.tween_callback(func():
		card_back.visible = false
		card_front.visible = true
	)
	
	flip.tween_property(card_pivot, "scale:x", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	
	await flip.finished
	
	# Temps de lecture
	await get_tree().create_timer(4.0).timeout
	
	# Disparition
	var fade_out = create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, 0.4)
	fade_out.tween_property(self, "scale", Vector2(0.8, 0.8), 0.4)
	
	await fade_out.finished
	hide()


# ────────────────────────────────────────
# Test automatique (à supprimer ou commenter en production)
func _ready() -> void:
	return
	#show_card(201)   # Test avec la première carte Caisse de Communauté
