extends Control

@onready var slider_musique: HSlider = $MainPanel/MarginContainer/Content/SliderMusique
@onready var slider_effets: HSlider = $MainPanel/MarginContainer/Content/SliderEffets
@onready var btn_sauvegarder: Button = $MainPanel/MarginContainer/Content/HBoxContainer/Sauvegarder
@onready var btn_quitter: Button =$MainPanel/MarginContainer/Content/HBoxContainer/Quitter
func _ready() -> void:
	# Initialisation
	slider_musique.value = SoundManager.lvl_music_settings
	slider_effets.value = SoundManager.lvl_fx_settings
	
	# Sécurité : Connexion des signaux si non faits dans l'éditeur
	if not btn_sauvegarder.pressed.is_connected(_on_sauvegarder_pressed):
		btn_sauvegarder.pressed.connect(_on_sauvegarder_pressed)
	if not btn_quitter.pressed.is_connected(_on_quitter_pressed):
		btn_quitter.pressed.connect(_on_quitter_pressed)

func _on_sauvegarder_pressed() -> void:
	SoundManager.play_clique()
	
	# 1. Mise à jour des valeurs stockées
	SoundManager.lvl_music_settings = slider_musique.value
	SoundManager.lvl_fx_settings = slider_effets.value
	
	# 2. Application immédiate pour la musique qui tourne déjà
	SoundManager.apply_music_volume()
	
	print("✅ Sauvegardé : Musique à ", SoundManager.lvl_music_settings, "/10")
	self.hide()

func _on_quitter_pressed() -> void:
	SoundManager.play_clique()
	# Reset des sliders sur les anciennes valeurs
	slider_musique.value = SoundManager.lvl_music_settings
	slider_effets.value = SoundManager.lvl_fx_settings
	self.hide()
