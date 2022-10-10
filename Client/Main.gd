extends Control

onready var status = get_node("Status")

const credit_text = '                *** Art: Simon Wüthrich  ***  Code: Oliver Dressler ***'
var credit_pos = 0
var last_credit = 0.0

func _ready():
# warning-ignore:return_value_discarded
	gamestate.connect("connection_failed", self, "_on_connection_failed")
# warning-ignore:return_value_discarded
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
# warning-ignore:return_value_discarded
	gamestate.connect("server_disconnected", self, "_on_server_disconnect")
	
# warning-ignore:return_value_discarded
	$JoinScreen/BtnCancel.connect("button_up", self, "hide_join")
# warning-ignore:return_value_discarded
	$JoinScreen/BtnJoin.connect("button_up", self, "join_pressed")
	
# warning-ignore:return_value_discarded
	$ChooseScreen/Btn_open.connect('button_up', self, "open_pressed")
	
	status.text = "Connecting... Do you have internet?"
	status.modulate = Color.yellow

func _on_connection_success():
	status.text = "Connected!"
	status.modulate = Color.green

func _on_connection_failed():
	status.text = "Connection Failed! Do you have internet?"
	status.modulate = Color.red

func _on_server_disconnect():
	status.text = "Server Disconnected! Do you have internet?"
	status.modulate = Color.red

func _on_JoinButton_button_up():
	$JoinScreen.show()

func hide_join():
	$JoinScreen.hide()
	
func join_pressed():
	var room_id = $JoinScreen/TextEdit.text
	gamestate.send_join_request(room_id)

func _on_HostButton_button_up():
	$ChooseScreen.show()
	
func open_pressed():
	gamestate.create_new_room($ChooseScreen.difficulty)
	
func _notification(note):
	# Handling back button
	if note == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		if gamestate.current_room_id == '':
			if $JoinScreen.visible:
				$JoinScreen.hide()
			elif $ChooseScreen.visible:
				$ChooseScreen.hide()
			else:
				get_tree().quit()
		else:
			var room = gamestate.get_current_room()
			if room.get_node('Lobby').visible:
				room.leave_game()
			else:
				room.show_leave_popup()

func _process(delta):
	last_credit += delta
	
	if last_credit >= 0.18:
		credit_pos = (credit_pos + 1) % len(credit_text)
		$credits.text = credit_text.substr(credit_pos, 18)
		last_credit = 0.0




