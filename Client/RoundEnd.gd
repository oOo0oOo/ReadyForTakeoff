extends Node2D

var arrows

func _ready():
	arrows = {
		-1: 'res://sprites/arrow_down.png',
		1: 'res://sprites/arrow_up.png'
	}
	
func setup(data):
	$Certificate/time.text = str(data['time']) + ' s'
	$Certificate/fails.text = str(data['fail_person'] + data['fail_challenge'])
	$Certificate/throttle.text = str(data['throttle']) + ' s'
	$phase.text = str(data['phase'])
	
	var reward = data['current_round'] != 0
	for cat in data['improvements'].keys():
		var val = int(data['improvements'][cat])
		
		if val == 0:
			get_node(cat + '_arrow').hide()
		else:
			var n = get_node(cat + '_arrow')
			n.show()
			n.texture = load(arrows[val])
			
		if val < 0:
			reward = false
	
	if reward:
		$round_end_award.show()
	else:
		$round_end_award.hide()
		
	# Change the airplane
	$airplane.texture = PortraitImages.airplanes[randi() % 5]
	
	$anim.play("display")
	
	if data['current_round'] == 17:
		$Space/anim.play("rocket")
