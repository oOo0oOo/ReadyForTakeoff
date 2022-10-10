extends Node2D

#onready var Player = load("res://Player.tscn")
onready var person_template = load('res://Person.tscn')
var airlines
var current_selection = -1
var has_throttled = false
var is_host = false
var num_players = 1

func _ready():
	# bind clicks from selection popup
# warning-ignore:return_value_discarded
	$Game/SelectionPopup/btn_back.connect("button_up", self, "popup_back")
	
# warning-ignore:return_value_discarded
	$Game/SelectionPopup/btn_container/btn_boarding.connect("button_up", self, "person_selected", ['boarding'])
# warning-ignore:return_value_discarded
	$Game/SelectionPopup/btn_container/btn_check_in.connect("button_up", self, "person_selected", ['check_in'])
# warning-ignore:return_value_discarded
	$Game/SelectionPopup/btn_container/btn_info.connect("button_up", self, "person_selected", ['info'])
# warning-ignore:return_value_discarded
	$Game/SelectionPopup/btn_container/btn_lost_and_found.connect("button_up", self, "person_selected", ['lost_and_found'])
# warning-ignore:return_value_discarded
	$Game/SelectionPopup/btn_container/btn_police.connect("button_up", self, "person_selected", ['police'])
# warning-ignore:return_value_discarded
	$Game/SelectionPopup/btn_container/btn_vip.connect("button_up", self, "person_selected", ['vip'])
	
# warning-ignore:return_value_discarded
	$LeavePopup/BtnCancel.connect("button_up", self, "hide_leave_popup")
# warning-ignore:return_value_discarded
	$LeavePopup/BtnOK.connect("button_up", self, "leave_game")
# warning-ignore:return_value_discarded
	$Game/btn_back.connect("button_up", self, 'show_leave_popup')
	
# warning-ignore:return_value_discarded
	$RoundEnd/btn_next_round.connect("button_up", self, 'on_btn_next_round')
# warning-ignore:return_value_discarded
	$RoundEnd/btn_replay.connect("button_up", self, 'on_btn_replay')
	
# warning-ignore:return_value_discarded
	$Game/Command/Timer.connect("timeout", self, "challenge_timeout")
	
# warning-ignore:return_value_discarded
	$Throttle/slider.connect("value_changed", self, "throttle_up")
	
	$Lobby/StartButton.hide()
	
	$Game.hide()
	$Lobby.hide()
	$RoundEnd.hide()
	$Throttle.hide()
	
func setup():
	# Request lobby data from the server
	rpc_id(1, "lobby_ready")
	pass

remote func update_lobby(data):
	$Lobby.show()
	$Lobby/Code.text = name
	if data['num_players'] > 1:
		$Lobby/Waiting.text = str(data['num_players']) + ' players are waiting'
	else:
		$Lobby/Waiting.text = '1 player is waiting'
	
	for i in range(8):
		if i < data['num_players']:
			$Lobby.get_node('silhouette' + str(i)).show()
		else:
			$Lobby.get_node('silhouette' + str(i)).hide()
			
	num_players = data['num_players']

remote func enable_lobby_host():
	is_host = true
# warning-ignore:return_value_discarded
	$Lobby/StartButton.connect('button_up', self, "on_btn_start_game")
	$Lobby/OnePlayerPopup/BtnOK.connect('button_up', self, "on_btn_force_start_game")
	$Lobby/OnePlayerPopup/BtnCancel.connect('button_up', self, "on_btn_hide_one_player_popup")
	$Lobby/StartButton.show()

func on_btn_start_game():
	if num_players == 1:
		$Lobby/OnePlayerPopup.show()
	else:
		rpc_id(1, "start_game")

func on_btn_force_start_game():
	rpc_id(1, "start_game")
	
func on_btn_hide_one_player_popup():
	$Lobby/OnePlayerPopup.hide()

func on_btn_next_round():
	rpc_id(1, "next_round")
	
func on_btn_replay():
	rpc_id(1, "replay")

remote func start_game(data):
	airlines = data['airlines']
	
	for c_type in ['boarding', 'check_in', 'info', 'lost_and_found', 'police', 'vip']:
		var btn = $Game/SelectionPopup/btn_container.get_node('btn_' + c_type)
		if data['challenge_types'].has(c_type):
			btn.show()
		else:
			btn.hide()
			
	has_throttled = false
	
	for n in $Game/PeopleContainer.get_children():
		n.queue_free()
		
	# Setup all people
	for p_id in data['people'].keys():
		add_person(p_id, data['people'][p_id])
	
	$Game.show()
	
	# This is so odd; Have to reset bc from second round the PeopleContainer is moved up??
	$Game/PeopleContainer.rect_position.y = 334
	
	$Game/Command.no_challenge()
	$RoundEnd.hide()
	$Lobby.hide()
	
	if data['show_tutorial']:
		$Tutorial.cur_page = 0
		$Tutorial.update_screen()
		$Tutorial.show()
	else:
		$Tutorial.hide()

func finish_tutorial():
	rpc_id(1, 'finish_tutorial')

remote func hide_tutorial():
	$Tutorial.hide()

func add_person(p_id, data):
	var person = person_template.instance()
	$Game/PeopleContainer.add_child(person)
	person.setup(p_id, data, airlines)
	person.get_node('Button').connect("button_up", self, "person_clicked", [p_id])

remote func add_challenge(data):
	$Game/Command.setup(data)
	
remote func remove_challenge():
	$Game/Command.no_challenge()

func person_clicked(p_id):
	current_selection = p_id
	var p_data = false
	for p in $Game/PeopleContainer.get_children():
		if p.p_id == p_id:
			p_data = p.data
			break
	
	if p_data:
		# Show popup
		$Game/PeopleContainer.hide()
		$Game/SelectionPopup/Person.setup(p_id, p_data, airlines)
		$Game/SelectionPopup.show()
	
func popup_back():
	current_selection = -1
	
	# Hide popup
	$Game/SelectionPopup.hide()
	$Game/PeopleContainer.show()

func person_selected(category):
	rpc_id(1, 'select_person', current_selection, category)
	popup_back()

remote func swap_people(swaps, success):
	for swap in swaps:
		for person in $Game/PeopleContainer.get_children():
			if person.p_id == swap[0]:
				if success:
					person.good()
				person.setup(swap[1], swap[2], airlines)
				person.get_node('Button').disconnect("button_up", self, "person_clicked")
				person.get_node('Button').connect("button_up", self, "person_clicked", [swap[1]])
				break

remote func fail_person(p_id):
	for person in $Game/PeopleContainer.get_children():
		if person.p_id == p_id:
			person.fail()
			break
			
remote func last_call():
	$Game/LastCall/anim.play("last_call")
	
remote func throttle():
	$Game.hide()
	$Throttle.show()
	$Throttle.start_anim()
	
func throttle_up(value):
	if not has_throttled && value > 90:
		has_throttled = true
		$Throttle.shake()
		rpc_id(1, 'click_throttle')
	
remote func finish_round(data):
	has_throttled = false
	$Throttle/slider.value = 0
	$Throttle.stop_shake()
	$Throttle.hide()
	
	if is_host:
		$RoundEnd/btn_next_round.show()
		$RoundEnd/btn_replay.show()
	else:
		$RoundEnd/btn_next_round.hide()
		$RoundEnd/btn_replay.hide()
	
	$RoundEnd.setup(data)
	$RoundEnd.show()

remote func fail_challenge():
	$Game/Command.fail()

func challenge_timeout():
	if !$RoundEnd.visible:
		rpc_id(1, 'challenge_timeout')

func leave_game():
	gamestate.send_leave_room_request()

func show_leave_popup():
	$LeavePopup.show()
	
func hide_leave_popup():
	$LeavePopup.hide()
