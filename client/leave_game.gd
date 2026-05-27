extends Panel

func _on_quitter_pressed() -> void:
	return
	
func _on_rester_pressed() -> void:
	SoundManager.play_clique()
	hide()
	return


func _on_quitterbutton_pressed() -> void:
	SoundManager.play_clique_negatif()
	return
