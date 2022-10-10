extends Control

var p_id = -1


var data 
var portrait_data

func setup(id, p_data, airlines, is_mr_x=false):
	data = p_data
	p_id = id
	if data.has('seat'):
		$Seat.text = data['seat']
	elif data.has('seat_row'):
		$Seat.text = str(data['seat_row']) + "?"
	elif data.has('seat_letter'):
		$Seat.text = "??" + data['seat_letter']
	else:
		$Seat.text = ""
	
	if data.has('luggage'):
		$Luggage.texture = load("res://sprites/luggage" + str(data['luggage']) + ".png")
		$Luggage.show()
	else:
		$Luggage.hide()
	
	if data.has('destination'):
		$Destination.text = data['destination']
		$Ticket.texture = load("res://sprites/ticket" + str(airlines[data['destination']]) + ".png")
	else:
		$Destination.text = ""
		$Ticket.texture = load("res://sprites/ticket_unknown.png")
	
	if not is_mr_x:
		portrait_data = $Portrait.setup(p_data, false)
		for p in portrait_data.keys():
			data[p] = portrait_data[p]
	else:
		$Portrait.rotation_degrees = 0


func fail():
	stop_animation()
	$Anim.play("bad")

func good():
	stop_animation()
	$Anim.play("good")

func stop_animation():
	if $Anim.is_playing():
		$Anim.seek(3, true)
		$Anim.stop()
