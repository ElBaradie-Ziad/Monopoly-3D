extends AnimatedSprite2D

@onready var target_position : Vector2 = position
@onready var _base_scale     : Vector2 = scale   # capture la scale définie dans dice_manager.tscn

func start_rolling():
	position   = target_position + Vector2(0, -200)
	modulate.a = 0
	rotation   = 0.0
	scale      = _base_scale   # restaure la bonne taille (ne pas écraser avec Vector2.ONE)
	show()

	play("rolling")

	# Chute rebondissante + fondu
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", target_position, 0.5)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

	# Wobble de rotation pendant le roulement
	var wobble = create_tween().set_loops(4)
	wobble.tween_property(self, "rotation_degrees",  18.0, 0.10).set_trans(Tween.TRANS_SINE)
	wobble.tween_property(self, "rotation_degrees", -18.0, 0.10).set_trans(Tween.TRANS_SINE)
	wobble.tween_property(self, "rotation_degrees",   0.0, 0.08).set_trans(Tween.TRANS_SINE)

func stop_on_value(value: int):
	stop()
	animation = "static"
	frame     = value - 1
	rotation  = 0.0
	# Rebond d'atterrissage — scale relative à la taille de base
	var bounce = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bounce.tween_property(self, "scale", _base_scale * 1.28, 0.10)
	bounce.tween_property(self, "scale", _base_scale,        0.18)
