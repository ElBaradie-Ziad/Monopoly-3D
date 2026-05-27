# TurnTimer.gd
# Nœud Control léger qui affiche un cercle de décompte (15 s).
# Utilisation :
#   _turn_timer.start(func(): <action_par_defaut>)
#   _turn_timer.stop()   ← à appeler quand le joueur agit avant la fin
#
# Le cercle change de couleur : vert → jaune → rouge.
# Il se dessine lui-même via _draw() — aucune texture requise.

extends Control

# ── Paramètres visuels ────────────────────────────────────────────────────────
const DURATION    : float = 15.0   # secondes
const RADIUS      : float = 28.0   # rayon de l'arc
const LINE_WIDTH  : float = 6.0    # épaisseur
const FONT_SIZE   : int   = 16     # taille du chiffre au centre

# ── État interne ──────────────────────────────────────────────────────────────
var _time_left        : float    = 0.0
var _active           : bool     = false
var _default_callback : Callable = Callable()

signal expired

# ── Cycle de vie ──────────────────────────────────────────────────────────────
func _ready() -> void:
	# Taille fixe centrée sur le cercle + marge pour le trait
	var diameter := (RADIUS + LINE_WIDTH) * 2.0
	custom_minimum_size = Vector2(diameter, diameter)
	size = Vector2(diameter, diameter)
	hide()
	set_process(false)

# ── API publique ──────────────────────────────────────────────────────────────

## Démarre le décompte. [default_callback] sera appelé si le temps expire.
func start(default_callback: Callable) -> void:
	_default_callback = default_callback
	_time_left = DURATION
	_active    = true
	show()
	set_process(true)
	queue_redraw()

## Arrête et cache le timer (à appeler quand le joueur agit lui-même).
func stop() -> void:
	_active = false
	set_process(false)
	hide()
	queue_redraw()

# ── Boucle principale ─────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not _active:
		return
	_time_left -= delta
	queue_redraw()
	if _time_left <= 0.0:
		_time_left = 0.0
		_active    = false
		set_process(false)
		hide()
		expired.emit()
		if _default_callback.is_valid():
			_default_callback.call()

# ── Dessin ────────────────────────────────────────────────────────────────────
func _draw() -> void:
	if not _active:
		return

	var center : Vector2 = size * 0.5
	var ratio  : float   = clampf(_time_left / DURATION, 0.0, 1.0)

	# Fond sombre semi-transparent
	draw_arc(center, RADIUS, 0.0, TAU, 64,
		Color(0.1, 0.1, 0.1, 0.70), LINE_WIDTH)

	# Arc coloré (vert → jaune → rouge selon ratio)
	var col : Color
	if ratio > 0.5:
		col = Color(0.22, 0.88, 0.35)   # vert
	elif ratio > 0.25:
		col = Color(0.95, 0.72, 0.10)   # jaune
	else:
		col = Color(0.92, 0.18, 0.12)   # rouge

	# L'arc part du sommet (−π/2) et tourne dans le sens horaire
	if ratio > 0.0:
		draw_arc(center, RADIUS,
			-PI * 0.5,
			-PI * 0.5 + TAU * ratio,
			64, col, LINE_WIDTH, true)

	# Chiffre au centre
	var label    : String = str(ceili(_time_left))
	var font     : Font   = ThemeDB.fallback_font
	var text_pos : Vector2 = center + Vector2(-FONT_SIZE * 0.28 * label.length(), FONT_SIZE * 0.35)
	draw_string(font, text_pos, label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
