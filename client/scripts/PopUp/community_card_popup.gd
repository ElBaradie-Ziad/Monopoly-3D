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
		push_error("CommunityCardPopup: Carte " + str(card_id) + " non trouvée")
		hide()
		return

	# Mise à jour du texte
	title_label.text = "CAISSE DE COMMUNAUTÉ"
	message_label.text = card.text

	# Couleur du titre selon le type
	if card.type == "positive":
		title_label.modulate = Color(1.0, 0.9, 0.2)
	elif card.type == "negative":
		title_label.modulate = Color(0.9, 0.2, 0.2)
	else:
		title_label.modulate = Color(1.0, 1.0, 1.0)

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

	# Animation selon le type de carte
	await _play_card_effect(card.get("type", "positive"))

	# Temps de lecture
	await get_tree().create_timer(3.2).timeout

	# Disparition
	var fade_out = create_tween()
	fade_out.set_parallel(true)
	fade_out.tween_property(self, "modulate:a", 0.0, 0.4)
	fade_out.tween_property(self, "scale", Vector2(0.8, 0.8), 0.4)
	await fade_out.finished
	hide()

# ────────────────────────────────────────
# Animation selon le type de carte
func _play_card_effect(type: String) -> void:
	match type:
		"positive":
			# Célébration dorée : flash + rebond
			var tw = create_tween().set_parallel(true)
			tw.tween_property(self, "modulate", Color(1.5, 1.25, 0.3, 1.0), 0.15)
			tw.tween_property(self, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			await tw.finished
			var tw2 = create_tween().set_parallel(true)
			tw2.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.35)
			tw2.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
			await tw2.finished

		"negative":
			# Flash rouge + tremblement
			var orig_x = position.x
			modulate = Color(1.4, 0.25, 0.25, 1.0)
			var shake = create_tween()
			for _i in range(5):
				shake.tween_property(self, "position:x", orig_x + 10.0, 0.05)
				shake.tween_property(self, "position:x", orig_x - 10.0, 0.05)
			shake.tween_property(self, "position:x", orig_x, 0.04)
			await shake.finished
			modulate = Color(1.0, 1.0, 1.0, 1.0)

		"special":
			# Lueur dorée pulsée
			var tw = create_tween().set_loops(2)
			tw.tween_property(self, "modulate", Color(1.3, 1.15, 0.15, 1.0), 0.25)
			tw.tween_property(self, "modulate", Color(1.0, 1.0,  1.0,  1.0), 0.25)
			await tw.finished

		_:
			pass

# ────────────────────────────────────────
func _ready() -> void:
	hide()
	#show_card(200)   # Test avec la première carte Caisse de Communauté
