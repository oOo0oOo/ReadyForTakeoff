extends Node2D

#signal timeout
onready var bg_no_image = load('res://sprites/infobox_no_pic.png')
onready var bg_image = load('res://sprites/infobox_pic.png')

var complete_text = ''
var cur_letter = 0
var since_last = 0
var finished_screen = false
var is_timed = false
var anim_started = false

var police_options = [
	'> A criminal\n', '> A smuggler\n', '> A loser\n', '> A thief\n',
	'> A crooked politician\n', '> A gangster\n', '> A mobster\n', '> A pirate\n',
	'> A bandit\n', '> A kidnapper\n', '> A fraudster\n'
]

var vip_options = [
	'> A celebrity\n', '> A musician\n', '> A famous actor\n', '> A superstar\n',
	'> A royal baby\n', '> A basketball star\n', '> A football star\n', '> A kung fu master\n',
	'> A boyband\n', '> A prime minister\n', '> An ignorant CEO\n', '> A big shot\n',
	'> A shaman\n', '> The king of Flowers\n', '> A famous freak\n', '> A rock star\n',
	'> The queen of Flowers\n'
]

func setup(data):
	var d = data[0]
	
	var is_not_image = false
	for other_cat in ['destination', 'seat_letter', 'seat_row', 'seat', 'luggage']:
		if d.has(other_cat):
			is_not_image = true
			break
	
	var who = data[3]['type'].replace('_', ' ').to_upper()
	if who == 'LOST AND FOUND':
		who = 'LOST & FOUND'
	
	var txt = '> ' + who
	if who in ['BOARDING', 'CHECK IN']:
		txt += ' open for:\n>\n'
	else:
		txt += ' is looking for:\n>\n'

	if d.has('destination'):
		txt += '> Destination: ' + d['destination'] + "\n"

	if d.has('seat'):
		txt += "> Seat: " + str(d['seat']) + '\n'

	else:
		if d.has('seat_row'):
			txt += "> Seat: " + str(d['seat_row']) + "?\n"

		elif d.has('seat_letter'):
			txt += "> Seat: ??" + d['seat_letter'] + '\n'

	if d.has('luggage'):
		if d['luggage'] == 0:
			txt += '> Luggage: None\n'
		elif d['luggage'] == 1:
			txt += '> Luggage: Normal\n'
		elif d['luggage'] == 2:
			txt += '> Luggage: Oversized\n'
	
	# If it is an image command show the infobox with pic
	var is_image = false
	for img_cat in ['shirt', 'hair', 'glasses']:
		if d.has(img_cat):
			is_image = true
			break

	if is_image:
		$Portrait.show()
		$Portrait.setup(d, true)
		
		if not is_not_image:
			if data[3]['type'].begins_with('police'):
				txt += police_options[randi() % len(police_options)]
			else:
				txt += vip_options[randi() % len(vip_options)]
		
		txt += '> See attached image ->\n'
	else:
		$Portrait.hide()
	
	$bad.hide()
	
	$AnimLED.stop()
	$task_led.hide()
	
	if data[3]['time'] != -1:
		$ProgressBar.max_value = data[3]['time']
		$Timer.start(data[3]['time'] + 0.01 * len(complete_text))
		is_timed = true
	else:
		$Timer.stop()
		is_timed = false
	
	$ProgressBar.hide()
	since_last = 0.0
	cur_letter = 0
	complete_text = txt
	finished_screen = false
	anim_started = false
	$Label.text = ''
	set_process(true)
	
func no_challenge():
	$Label.text = '>'
	$ProgressBar.hide()
	$Portrait.hide()
	
	$AnimLED.stop()
	$task_led.hide()
	$Timer.stop()
	
func _process(delta):
	since_last += delta
	
	if since_last >= 0.01 and !finished_screen:
		since_last = 0
		cur_letter += 1
		
		$Label.text = complete_text.substr(0, cur_letter)
		
		if cur_letter >= len(complete_text):
			finished_screen = true
			if is_timed:
				$ProgressBar.show()
		
	if is_timed and finished_screen:
		$ProgressBar.value = $Timer.time_left
		if $Timer.time_left <= 10.0 and !anim_started:
			$AnimLED.play("LED")
			anim_started = true

func fail():
	$AnimLED.stop()
	$Anim.play('bad')
