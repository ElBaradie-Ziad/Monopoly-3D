extends Node
#
var music_player : AudioStreamPlayer
var lvl_music_settings : float = 5.0 # Echelle 0 à 10
var lvl_fx_settings : float = 5.0    # Echelle 0 à 10

func _ready() -> void:
	# On prépare le music_player une seule fois au lancement du jeu
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Music"
const SOUNDS = {
	## ── 1. Gameplay principal ──
	## Dés
	"dice_roll": 
		preload("res://assets/sounds/game/dice_roll.mp3"),
		#FAIT
	"dice_stop": 
		preload("res://assets/sounds/game/dice_stop.mp3"),
		#FAIT
	"dice_double": 
		preload("res://assets/sounds/game/dice_double.mp3"),
	#FAIT
	## Déplacement
	"step": 
		preload("res://assets/sounds/game/step.mp3"),
	#FAIT
	"step_final": 
		preload("res://assets/sounds/game/step_final.mp3"),
	#FAiT
	
	
	## CASE
	"card_flip": preload("res://assets/sounds/game/card-flip.mp3"),
	#FAIT
	
	"train": preload("res://assets/sounds/game/bt-train-whistle.mp3"),
	#FAIT
	"coffre": preload("res://assets/sounds/game/Drawer_open.wav.mp3"),
	#FAiT
	"prison": preload("res://assets/sounds/game/prison.mp3"),
	#FAIT
	"compagnie_eau": preload("res://assets/sounds/game/water-splash-9.mp3"),
	#FAIT
	"buy": preload("res://assets/sounds/game/buy_1.mp3"),
	#FAIT
	"dont_buy": preload("res://assets/sounds/game/Enchanting_Table_enchant2.ogg.mp3"),
	#FAIT
	
	"victory": preload("res://assets/sounds/game/victory_6.mp3"),
	
	"defeat": preload("res://assets/sounds/game/defeat.mp3"),
	
	"money_gain": preload("res://assets/sounds/game/kaching-sound-fx.mp3"),
	
	"money_loose": preload("res://assets/sounds/game/Player_hurt3.ogg.mp3"),
	
	"day_start": preload("res://assets/sounds/game/dragon-studio-rooster-crowing-364473.mp3"),
	
	"night_start": preload("res://assets/sounds/game/felix_quinol-cricket-sound-113945.mp3"),
	
	"explosion" : preload("res://assets/sounds/game/Explosion3.ogg.mp3"),
	
	"siren" : preload(("res://assets/sounds/game/siren.mp3")),
	
	"voleur": preload("res://assets/sounds/game/voleur.ogg.mp3"),
	## MENU X MUSIQUE
	
	"music": preload("res://assets/sounds/music/Minecraft.ogg.mp3"),
	
	"clique": preload("res://assets/sounds/ui/Click_stereo.ogg.mp3"),
	
	"clique2": preload("res://assets/sounds/ui/snd_sys_confirm.wav"),
	
	"clique_negatif": preload("res://assets/sounds/ui/error-notification.mp3"),
	
	"depart": preload("res://assets/sounds/game/case_depart.mp3"),
	
	"electricite": preload("res://assets/sounds/game/electricity_us849kj.mp3"),
	
	"loyer": preload("res://assets/sounds/game/propriété.mp3"),
	
	"house_build": preload("res://assets/sounds/game/house_build.mp3")
	
	
}
#


func _get_db_from_settings(value: float) -> float:
	if value <= 0:
		return -80.0 # Silence absolu
	
	# On transforme l'échelle 0-10 en 0.0-1.0, puis en dB
	# linear_to_db(1.0) = 0dB (Max) | linear_to_db(0.01) ~= -40dB
	return linear_to_db(value / 10.0)
	
func apply_music_volume() -> void:
	if music_player:
		music_player.volume_db = _get_db_from_settings(lvl_music_settings)

# ====================== GESTION DE LA MUSIQUE ======================
func play_music(sound_name: String, volume_db: float = -10.0) -> void:
	if not SOUNDS.has(sound_name):
		return

	# On s'assure que le nœud est prêt
	if not music_player.is_inside_tree():
		await get_tree().process_frame

	# 1. MISE À JOUR DU VOLUME SYSTÉMATIQUE
	# On utilise la valeur des paramètres plutôt que l'argument par défaut
	apply_music_volume()

	# 2. GESTION DU FLUX
	if music_player.stream == SOUNDS[sound_name] and music_player.playing:
		# La musique joue déjà, on ne fait rien d'autre que la mise à jour du volume (faite au dessus)
		return
	
	music_player.stream = SOUNDS[sound_name]
	music_player.play()

# Ta fonction pour appliquer le volume en direct


func stop_music() -> void:
	music_player.stop()


## ====================== FONCTIONS DE JEU ======================
func play(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not SOUNDS.has(sound_name): return
	
	# Si le réglage FX est à 0, on ne crée même pas le nœud (optimisation)
	if lvl_fx_settings <= 0: return

	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = SOUNDS[sound_name]
	
	# On combine le volume de base du son avec le réglage global
	audio_player.volume_db = volume_db + _get_db_from_settings(lvl_fx_settings)
	
	audio_player.pitch_scale = pitch_scale
	add_child(audio_player)
	audio_player.play()
	
	await audio_player.finished
	audio_player.queue_free()

# ====================== SON DES DÉS (avec animation) ======================
func play_dice(dice1: int, dice2: int) -> void:
	# 1. Joue plusieurs sons de lancer pendant l'animation (15 frames ≈ 0.5s à 30fps)
	for i in range(10):                    # On joue 5 sons de roll (ajustable)
		play("dice_roll", lvl_fx_settings, 0.9 + randf() * 0.2)  # petite variation de pitch
		await get_tree().create_timer(0.15).timeout     # délai entre chaque son (~15 frames total)
	
	# 2. Joue le son d'arrêt des dés
	play("dice_stop", -4.0)
	
	# 3. Si double, joue le son spécial après un petit délai
	if dice1 == dice2:
		await get_tree().create_timer(0.15).timeout
		play("dice_double", -3.0)
		
# ====================== SON DE DÉPLACEMENT DU PION ======================
func play_step(steps: int) -> void:
	if steps <= 0:
		return
	
	# 1. Joue le son "step" plusieurs fois (une fois par case parcourue)
	for i in range(steps - 1):           # steps - 1 fois le son normal
		play("step", lvl_fx_settings, 0.95 + randf() * 0.15)   # petite variation de pitch
		await get_tree().create_timer(0.3).timeout   # délai entre chaque pas (~ rapide)
	
	# 2. Joue le son final "step_final" sur la dernière case
	await get_tree().create_timer(0.3).timeout
	play("step_final", -7.0, 1.0)

func play_carte_flip() -> void:
	play("card_flip",lvl_fx_settings, 0.95 + randf() * 0.15)
	
func play_siren() -> void:
	play("siren",lvl_fx_settings, 0.95 + randf() * 0.15)

func house_build() -> void:
	play("house_build",lvl_fx_settings, 0.95 + randf() * 0.15)

func play_loyer() -> void:
	play("loyer",lvl_fx_settings, 0.95 + randf() * 0.15)

func play_depart() -> void:
	play("depart",lvl_fx_settings, 0.95 + randf() * 0.15)

func play_train()->void:
	play("train",lvl_fx_settings, 0.95 + randf() * 0.15)

func play_voleur()->void:
	play("voleur",lvl_fx_settings, 0.95 + randf() * 0.15)

func play_coffre()->void:
	play("coffre",lvl_fx_settings, 0.95 + randf() * 0.15)

func play_electrcite()->void:
	play("electricite",lvl_fx_settings, 0.95 + randf() * 0.15)

func play_prison()->void:
	play("prison",lvl_fx_settings, 0.95 + randf() * 0.15)

func play_eau()->void:
	play("compagnie_eau",lvl_fx_settings, 0.95 + randf() * 0.15)

func play_buy()->void:
	play("buy",lvl_fx_settings, 0.95 + randf() * 0.15)
	
func play_dontbuy()->void:
	play("dont_buy",lvl_fx_settings, 0.95 + randf() * 0.15)


func play_clique()->void:
	play("clique",lvl_fx_settings, 0.95 + randf() * 0.15)


func play_clique2()->void:
	play("clique2",lvl_fx_settings, 0.95 + randf() * 0.15)


func play_clique_negatif()->void:
	play("clique_negatif",lvl_fx_settings, 0.95 + randf() * 0.15)
