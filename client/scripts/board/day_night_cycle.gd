# day_night_cycle.gd
# Gère le cycle jour/nuit du plateau.
# Chaque 5 tours, la lumière et le ciel transitionnent progressivement.
#
# Usage depuis sandbox_board.gd :
#   _day_night.init($DirectionalLight3D, $WorldEnvironment)
#   _day_night.on_turn_end()  ← appelé à chaque fin de tour

extends Node

signal cycle_changed(is_night: bool)

# ── Paramètres ───────────────────────────────────────────────────────────────
@export var turns_per_cycle  : int   = 5      ## Nombre de tours entre chaque transition
@export var transition_dur   : float = 3.0    ## Durée de la transition jour↔nuit (secondes)
@export var day_energy       : float = 1.2    ## Intensité soleil le jour
@export var night_energy     : float = 0.15   ## Intensité lune la nuit
@export var day_angle        : float = -45.0  ## Angle X du soleil (jour)
@export var night_angle      : float = -170.0 ## Angle X de la lune (nuit)

# Couleurs lumière directionnelle
const DAY_COLOR   : Color = Color(1.00, 0.95, 0.85)   # Blanc chaud
const SUNSET_COLOR: Color = Color(1.00, 0.55, 0.20)   # Orange coucher de soleil
const NIGHT_COLOR : Color = Color(0.25, 0.30, 0.55)   # Bleu nuit

# ── État ─────────────────────────────────────────────────────────────────────
var _dir_light        : DirectionalLight3D = null
var _environment      : WorldEnvironment   = null
var _turn_counter     : int   = 0
var _is_night         : bool  = false
var _progress         : float = 0.0   # 0.0 = plein jour, 1.0 = pleine nuit
var _house_lights     : Array = []   # OmniLight3D dans les maisons


# ════════════════════════════ API publique ════════════════════════════════════

func init(dir_light: DirectionalLight3D, env: WorldEnvironment) -> void:
	_dir_light   = dir_light
	_environment = env
	_apply_day_instant()

## Appelé à chaque fin de tour (depuis GameScene ou sandbox_board).
## La transition s'étale sur `turns_per_cycle` tours : chaque tour applique
## 1/N de la variation totale, donc la scène change progressivement.
func on_turn_end() -> void:
	_turn_counter += 1
	var step : float = 1.0 / float(turns_per_cycle)

	# Avancer le progrès vers la prochaine cible (nuit ou jour)
	var target : float
	if not _is_night:
		target = clampf(float(_turn_counter) * step, 0.0, 1.0)
	else:
		target = clampf(1.0 - float(_turn_counter) * step, 0.0, 1.0)

	await _apply_progress(target)

	if _turn_counter >= turns_per_cycle:
		_turn_counter = 0
		_is_night = !_is_night
		cycle_changed.emit(_is_night)
		_set_house_lights(_is_night)

## Enregistre une lumière de maison pour l'activer la nuit
func register_house_light(light: OmniLight3D) -> void:
	_house_lights.append(light)
	light.visible = _is_night

## Supprime une lumière de maison (quand maison détruite)
func unregister_house_light(light: OmniLight3D) -> void:
	_house_lights.erase(light)


# ════════════════════════════ Transitions ════════════════════════════════════

## Applique un état intermédiaire t ∈ [0,1] (0 = jour, 1 = nuit) avec un
## court tween correspondant à un seul tour.  La couleur passe par le coucher
## de soleil (orange) au milieu de la transition.
func _apply_progress(t: float) -> void:
	if _dir_light == null:
		_progress = t
		return

	_progress = t

	# Couleur : DAY → SUNSET (première moitié) puis SUNSET → NIGHT (deuxième moitié)
	var target_color : Color
	if t <= 0.5:
		target_color = DAY_COLOR.lerp(SUNSET_COLOR, t * 2.0)
	else:
		target_color = SUNSET_COLOR.lerp(NIGHT_COLOR, (t - 0.5) * 2.0)

	var target_energy : float = lerpf(day_energy,  night_energy, t)
	var target_angle  : float = lerpf(day_angle,   night_angle,  t)

	# Durée d'un seul pas = durée totale divisée par le nombre de tours
	var step_dur : float = transition_dur / float(turns_per_cycle)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_dir_light, "light_color",        target_color,  step_dur).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_dir_light, "light_energy",       target_energy, step_dur).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_dir_light, "rotation_degrees:x", target_angle,  step_dur).set_trans(Tween.TRANS_SINE)
	await tw.finished

func _apply_day_instant() -> void:
	_progress = 0.0
	_turn_counter = 0
	_is_night = false
	if _dir_light == null:
		return
	_dir_light.light_color        = DAY_COLOR
	_dir_light.light_energy       = day_energy
	_dir_light.rotation_degrees.x = day_angle

func _set_house_lights(on: bool) -> void:
	for light in _house_lights:
		if is_instance_valid(light):
			light.visible = on
