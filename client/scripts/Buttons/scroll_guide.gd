extends Button

@export var scroll_container: ScrollContainer
@export var target_label: Control
@export var duration: float = 0.45

var tween: Tween
var highlight_tween: Tween


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if scroll_container == null:
		push_warning("ScrollContainer non assigné.")
		return

	if target_label == null:
		push_warning("Target label non assigné.")
		return

	await get_tree().process_frame

	var target_scroll: int = max(0, int(target_label.position.y))

	if tween != null:
		tween.kill()

	tween = create_tween()
	tween.tween_property(
		scroll_container,
		"scroll_vertical",
		target_scroll,
		duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	tween.finished.connect(_highlight_target)


func _highlight_target() -> void:
	if target_label == null:
		return

	if highlight_tween != null:
		highlight_tween.kill()

	var label := target_label as Label
	if label == null:
		return

	var original_color: Color = label.modulate

	highlight_tween = create_tween()
	highlight_tween.tween_property(label, "modulate", Color(0.762, 0.0, 0.026, 1.0), 0.25)
	highlight_tween.tween_interval(0.35)
	highlight_tween.tween_property(label, "modulate", original_color, 0.35)
