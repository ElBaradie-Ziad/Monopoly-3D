extends Control

@export var normal_scale := Vector2(1.0, 1.0)
@export var hover_scale := Vector2(1.04, 1.04)
@export var pressed_scale := Vector2(0.96, 0.96)

@export var normal_color := Color(1, 1, 1, 0.0)
@export var hover_color := Color(1, 1, 1, 0.2)
@export var pressed_color := Color(1, 1, 1, 0.35)
@export var selected_color := Color(1.0, 0.9, 0.0, 0.9) # Le jaune de sélection

var button: BaseButton
var color_rect: ColorRect
var tween: Tween
var is_selected := false # On mémorise si ce bouton est le choix actuel

func _ready():
	await get_tree().process_frame
	_find_nodes()

	if !button or !color_rect:
		push_error("Button ou ColorRect introuvable")
		return

	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.color = normal_color

	button.mouse_entered.connect(func(): _apply(hover_scale, hover_color))
	button.mouse_exited.connect(func(): _apply(normal_scale, normal_color))
	button.button_down.connect(func(): _apply(pressed_scale, pressed_color))
	button.button_up.connect(func():
		_apply(
			hover_scale if button.is_hovered() else normal_scale,
			hover_color if button.is_hovered() else normal_color
		)
	)

	pivot_offset = size / 2

func _find_nodes():
	for c in get_children():
		if c is BaseButton:
			button = c
		elif c is ColorRect:
			color_rect = c

func _apply(s: Vector2, col: Color):
	if tween:
		tween.kill()

	tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", s, 0.1)
	
	# Si sélectionné, on force le jaune. Sinon, on utilise la couleur normale/hover.
	var target_color = selected_color if is_selected else col
	tween.tween_property(color_rect, "color", target_color, 0.1)

# Fonction appelée par ton script principal pour activer/désactiver le jaune
func set_selected(selected: bool) -> void:
	is_selected = selected
	
	# SÉCURITÉ : Si la fonction est appelée au démarrage avant que _ready ait trouvé le bouton
	if button == null or color_rect == null:
		return
		
	# On rafraîchit l'affichage tout de suite
	_apply(
		hover_scale if button.is_hovered() else normal_scale,
		hover_color if button.is_hovered() else normal_color
	)
