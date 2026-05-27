extends Control

@onready var die1 = $MenuFond/MarginContainer/VBoxContainer/DiceContainer/SlotDe1/Die1
@onready var die2 = $MenuFond/MarginContainer/VBoxContainer/DiceContainer/SlotDe2/Die2
@onready var result_label = $MenuFond/MarginContainer/VBoxContainer/ResultLabel

var is_animating : bool = false

func _ready():
	result_label.text = "Lancement..."
	hide()
		

func run_dice_animation(val1: int, val2: int):
	if is_animating:
		return
	is_animating = true
	result_label.text = "Les dés roulent..."
	
	# Lancement des animations de chute et roll
	die1.start_rolling()
	die2.start_rolling()
	SoundManager.play_dice(val1,val2)
	_shake_container()  # secousse du conteneur (fire-and-forget)

	# Attente de la fin de l'animation (ajustée à ton timer de chute)
	await get_tree().create_timer(1.5).timeout
	
	# Arrêt sur les faces finales
	die1.stop_on_value(val1)
	die2.stop_on_value(val2)

	# Mise à jour du texte avec le total
	var total = val1 + val2
	var a_fait_double = (val1 == val2)

	if a_fait_double:
		result_label.text = "DOUBLE !  %d + %d" % [val1, val2]
		_animate_result_text()
		await _celebrate_double()
	else:
		result_label.text = "Résultat : " + str(total)
		_animate_result_text()

	await get_tree().create_timer(2.0).timeout  # laisse le résultat visible 2s
	hide()
	is_animating = false

## Secousse rapide du panneau des dés pendant le roulement.
func _shake_container() -> void:
	var orig : Vector2 = $MenuFond.position
	var shake := create_tween()
	for _i in range(8):
		shake.tween_property($MenuFond, "position",
			orig + Vector2(randf_range(-5.0, 5.0), randf_range(-4.0, 4.0)), 0.06)
	shake.tween_property($MenuFond, "position", orig, 0.05)

func _animate_result_text():
	var tween = create_tween()
	tween.tween_property(result_label, "modulate", Color.YELLOW, 0.2)
	tween.tween_property(result_label, "modulate", Color.WHITE,  0.2)

# Flash doré sur label + dés × 3 pour célébrer le double
func _celebrate_double() -> void:
	for _i in range(3):
		var tw = create_tween().set_parallel(true)
		tw.tween_property(result_label, "modulate", Color(1.0, 0.85, 0.1, 1.0), 0.15)
		tw.tween_property(die1, "modulate", Color(1.5, 1.2, 0.2, 1.0), 0.15)
		tw.tween_property(die2, "modulate", Color(1.5, 1.2, 0.2, 1.0), 0.15)
		await tw.finished
		var tw2 = create_tween().set_parallel(true)
		tw2.tween_property(result_label, "modulate", Color.WHITE, 0.15)
		tw2.tween_property(die1, "modulate", Color.WHITE, 0.15)
		tw2.tween_property(die2, "modulate", Color.WHITE, 0.15)
		await tw2.finished
