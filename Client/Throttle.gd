extends Node2D

var since_last = 0
var cur_letter = 0
var complete_text = '> Everybody\n> throttle up\n> at the SAME TIME!\n> ...'
var shaking = false
var text_finished = false

func _on_slider_value_changed(value):
	var sc = -0.1 + (value / 100) * 0.4
	if sc == 0:
		sc = 0.00000001
	
	$throttle_handle.scale.y = sc

func start_anim():
	since_last = 0
	cur_letter = 0
	text_finished = false
	set_process(true)

func _process(delta):
	if delta < 0.1:
		since_last += delta
	
	if since_last >= 0.025 and !text_finished:
		since_last = 0
		cur_letter += 1
		
		$Label.text = complete_text.substr(0, cur_letter)
		
		if cur_letter >= len(complete_text):
			set_process(false)
			text_finished = true
	
	if shaking:
		position = Vector2(randi() % 10 - 5, randi() % 10 - 5)

func shake():
	$Label.text = '> LIFTOFF!\n> LIFTOFF!\n> LIFTOFF!\n> LIFTOFF!'
	shaking = true
	text_finished = true
	set_process(true)
	
func stop_shake():
	position = Vector2(0, 0)
	shaking = false
	set_process(false)
