extends Node2D

var difficulty = 0

func _ready():
	update_screen()

func _on_btn_left_button_up():
	difficulty = (difficulty + 2) % 3
	update_screen()

func _on_btn_right_button_up():
	difficulty = (difficulty + 1) % 3
	update_screen()
	
func update_screen():
	$Difficulty.text = ['Tiny Airfield\n(easy)', 'Rural Airport\n(medium)', 'National Airport\n(hard)'][difficulty]
	$airport.texture = load('res://sprites/airport' + str(difficulty) + '.png')

