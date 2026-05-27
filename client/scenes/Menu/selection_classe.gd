extends VBoxContainer

# On stocke les références pour y accéder facilement
@onready var classes = [$"Classe 1", $"Classe 2", $"Classe 3"]
var selected_color = Color(1.0, 0.9, 0.0, 0.9)
var idle_color = Color(1.0, 0.9, 0.0, 0.0) # Opacité à 0

func _ready():
	# On initialise chaque panel
	for i in range(classes.size()):
		var panel = classes[i]
		var index = i + 1 # Pour avoir 1, 2 ou 3
		
		# On connecte le signal de clic dynamiquement
		panel.gui_input.connect(_on_class_gui_input.bind(panel, index))
		
		# Optionnel : S'assurer que tout est éteint au départ 
		# (ou allumer celui par défaut dans Global.select_classe)
		_update_ui_display()

func _on_class_gui_input(event: InputEvent, panel: Control, index: int):
	# On vérifie si c'est un clic gauche de la souris
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_class(index)

func select_class(index: int):
	# 1. Mise à jour de la variable globale
	Global.select_classe = index
	print("Classe sélectionnée : ", Global.select_classe)
	
	# 2. Mise à jour visuelle
	_update_ui_display()

func _update_ui_display():
	for i in range(classes.size()):
		var panel = classes[i]
		var color_rect = panel.get_node("ColorRect")
		var current_index = i + 1
		
		if current_index == Global.select_classe:
			color_rect.color = selected_color
		else:
			color_rect.color = idle_color
