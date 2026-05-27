# rent_hurt_effect.gd
# Animation "Hurt" quand un joueur paie un loyer élevé :
#   1. Flash rouge sur tout l'écran
#   2. Knockback du pion (recul + retour)
#
# Usage depuis sandbox_board.gd :
#   _rent_hurt.play(pawn_node, knockback_dir)
#   await _rent_hurt.finished

extends Node

signal finished

# ── Paramètres ───────────────────────────────────────────────────────────────
@export var flash_color     : Color = Color(1.0, 0.0, 0.0, 0.45)  ## Couleur du flash
@export var flash_duration  : float = 0.35   ## Durée totale du flash
@export var knockback_dist  : float = 0.4    ## Distance de recul en unités monde
@export var knockback_dur   : float = 0.15   ## Durée du recul
@export var return_dur      : float = 0.25   ## Durée du retour


# ════════════════════════════ API publique ════════════════════════════════════

## Joue l'animation hurt sur le pion donné.
## [param pawn_node]     : le Node3D du pion (PawnController)
## [param owner_pos]     : position du propriétaire pour calculer la direction du knockback
func play(pawn_node: Node3D, owner_pos: Vector3) -> void:
	# Lancer le flash et le knockback en parallèle
	_flash_screen()
	await _knockback(pawn_node, owner_pos)
	SoundManager.play_voleur()
	finished.emit()


# ════════════════════════════ Flash écran ════════════════════════════════════

func _flash_screen() -> void:
	# Créer un CanvasLayer + ColorRect temporaire
	var canvas := CanvasLayer.new()
	var rect   := ColorRect.new()
	rect.color = flash_color
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	get_tree().root.add_child(canvas)

	# Fade in rapide → fade out
	var tw := canvas.create_tween()
	tw.tween_property(rect, "color:a", flash_color.a, flash_duration * 0.2)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(rect, "color:a", 0.0, flash_duration * 0.8)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	canvas.queue_free()


# ════════════════════════════ Knockback ══════════════════════════════════════

func _knockback(pawn_node: Node3D, owner_pos: Vector3) -> void:
	if not is_instance_valid(pawn_node):
		return

	var origin_pos : Vector3 = pawn_node.global_position

	# Direction de recul = loin du propriétaire, sur le plan XZ
	var dir := (pawn_node.global_position - owner_pos)
	dir.y = 0.0
	if dir.is_zero_approx():
		dir = Vector3(1, 0, 0)  # direction par défaut si même position
	dir = dir.normalized()

	var knockback_pos : Vector3 = origin_pos + dir * knockback_dist

	# Phase 1 : recul rapide
	var tw := pawn_node.create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(pawn_node, "global_position", knockback_pos, knockback_dur)\
		.set_ease(Tween.EASE_OUT)
	# Phase 2 : retour avec un petit rebond
	tw.tween_property(pawn_node, "global_position", origin_pos, return_dur)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tw.finished
