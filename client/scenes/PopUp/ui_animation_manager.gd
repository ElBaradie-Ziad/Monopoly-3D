extends Node

# Paramètres configurables (tu peux les modifier dans l'inspecteur de la scène)
@export var money_duration: float = 0.65
@export var punch_scale: float = 1.38
@export var gain_color: Color = Color(0.3, 1.0, 0.4)
@export var loss_color: Color = Color(1.0, 0.35, 0.35)



var floating_container: CanvasLayer

func _ready():
	floating_container = CanvasLayer.new()
	floating_container.layer = 200
	add_child(floating_container)

# ====================== ANIMATION SUR LABEL ======================
# UiAnimationManager.gd
func animate_label(label: Label, start_v: int, end_v: int) -> void:
	if not label: return
	
	var delta = end_v - start_v
	var is_gain = delta > 0
	
	# Création du tween principal
	var tween = label.create_tween().set_parallel(true)
	
	# Couleur temporaire
	label.add_theme_color_override("font_color", gain_color if is_gain else loss_color)
	
	# Animation des chiffres
	tween.tween_method(
		func(v: float): label.text = str(int(round(v))) + " M",
		float(start_v),
		float(end_v),
		money_duration
	)
	
	# Effet de punch (Scale)
	var original_scale = Vector2.ONE # Ou récupère la scale initiale
	tween.tween_property(label, "scale", Vector2.ONE * punch_scale, 0.1).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "scale", original_scale, 0.2).set_delay(0.1)
	
	# ATTENTE : On attend que ce tween précis soit fini
	await tween.finished
	
	# Nettoyage
	label.remove_theme_color_override("font_color")
# ====================== FLOATING TEXT ======================
func spawn_floating_money(amount: int, screen_position: Vector2, duration: float = 1.4) -> void:
	if not floating_container:
		return
	
	var floating_scene = preload("res://scenes/PopUp/floating_money.tscn")
	var instance: Control = floating_scene.instantiate()
	
	floating_container.add_child(instance)
	instance.global_position = screen_position
	instance.show_value(amount, duration)
