extends Control

@export var normal_scale := Vector2(1.0, 1.0)
@export var hover_scale := Vector2(1.04, 1.04)
@export var pressed_scale := Vector2(0.96, 0.96)

@export var normal_color := Color.html("#00000096")
@export var hover_color := Color.html("#2A2A2AB0")
@export var pressed_color := Color.html("#111111CC")
@export var selected_color := Color.html("#FFD700DD")

var button: BaseButton
var color_rect: ColorRect
var tween: Tween
var is_selected := false # On mémorise si ce bouton est le choix actuel

func _find_nodes():
	# On cherche dans les enfants
	for c in get_children():
		if c is BaseButton:
			button = c
		elif c is ColorRect:
			color_rect = c

func _ready():
	# Petit délai pour laisser le temps aux nœuds de se charger
	await get_tree().process_frame
	_find_nodes()

	if !button:
		# Si on n'a toujours pas de bouton, on cherche dans le PARENT
		# C'est souvent le cas si le script est sur un ColorRect enfant d'un bouton
		if get_parent() is BaseButton:
			button = get_parent()

	if !button:
		#push_error("ERREUR : Aucun bouton trouvé pour le script sur : " + name)
		return

	# Très important pour l'effet d'échelle (Shadow/Scale)
	pivot_offset = size / 2 
	
	# Si tu as un ColorRect pour le fond
	if color_rect:
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		color_rect.color = normal_color

	# Connexions sécurisées
	button.mouse_entered.connect(func(): _apply(hover_scale, hover_color))
	button.mouse_exited.connect(func(): _apply(normal_scale, normal_color))
	button.button_down.connect(func(): _apply(pressed_scale, pressed_color))
	button.button_up.connect(func():
		var target_s = hover_scale if button.is_hovered() else normal_scale
		var target_c = hover_color if button.is_hovered() else normal_color
		_apply(target_s, target_c)
	)

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


func _on_button_leave_pressed()-> void:
	SoundManager.play_clique()
	$"../../../../Settings".hide()
	$"../../../../QuitterPannel".hide()
	$"../../../../QuitterPannel".show()

var info = 1
func _on_button_info()-> void:
	
	$"../../../../Settings".hide()
	$"../../../../QuitterPannel".hide()
	SoundManager.play_clique()
	if info % 2 == 0:
		$"../../../../DroitPannel".show()
	else:
		$"../../../../DroitPannel".hide()
	info+=1


func _on_button_settings()-> void:
	$"../../../../QuitterPannel".hide()
	SoundManager.play_clique()
	$"../../../../Settings".show()

func _on_camera_pressed()-> void:
	SoundManager.play_clique()
	Global.is_global_view = !Global.is_global_view
	if(Global.is_global_view):
		Global.request_camera_global_view.emit()
	else:
		Global.request_camera_pion_view.emit()


func _on_quitterbutton_pressed() -> void:
	SoundManager.play_clique_negatif()
	ReseauManager._send_action(11)
	get_tree().change_scene_to_file("res://main_menu_v2.tscn")
	pass # Replace with function body.
