extends Control

@onready var label: Label = $Label

func show_value(amount: int, duration: float = 1.4) -> void:
	label.text = ("+" if amount >= 0 else "") + str(amount)
	label.modulate = UiAnimationManager.gain_color if amount >= 0 else UiAnimationManager.loss_color
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 110, duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.7).set_delay(duration * 0.4)
	
	await tween.finished
	queue_free()
