extends Node2D


var host_id = -1
var started = false
var player_ids = []
var num_players
var current_round = 0

var fake_player = false

var game

var last_statistics = false
var current_statistics = false

var round_ended = false
var round_end_delay = 0.0
var num_tutorial_finished = 0

#####
#
# Player management and lobby
#
#####

func _ready():
	set_process(false)

func add_player(id):
	if not started:
		if len(get_players()) < config.MAX_PLAYERS:
			
			var player_template = load("res://Player.tscn")
			var player = player_template.instance()
			
			# This is important
			player.name = String(id)
			player.set_network_master(id)
			
			add_child(player)
			return true
	return false


func remove_player(id):
	var remaining = len(get_parent().get_children()) - 1
	print('This is the end... ' + str(remaining) + ' games remaining.')
	self.queue_free()


remote func lobby_ready():
	# A user has successfully loaded the lobby, we update data for everyone
	var caller_id = get_tree().get_rpc_sender_id()
	
	var data = {
		'num_players': len(get_players())
	}
	rpc("update_lobby", data)
	
	# Enable to host to start the game
	if caller_id == host_id:
		rpc_id(caller_id, "enable_lobby_host")


#####
#
# The Game
#
#####
	
remote func start_game(local=false):
	if not local:
		var caller_id = get_tree().get_rpc_sender_id()
		if caller_id != host_id:
			return 
	
	num_players = len(get_players())
	
	# Collect all player_ids; translate to range(num_players)
	player_ids = []
	for player in get_players():
		if player.id:
			player_ids.append(player.id)
		else:
			player_ids.append(-1)
	
	started = true
	
	var game_template = load("res://Game.tscn")
	game = game_template.instance()
	add_child(game)
	
	start_next_round()

func start_next_round():
	game.setup(self, num_players, current_round)
	
	# Determine airline color once at the beginning of the game
	var tickets = range(5)
	tickets.shuffle()
	var airlines = {}
	for destination in game.branch_options['destination']:
		airlines[destination] = tickets.pop_back()
	
	# Also send which types of challenges we have
	var c_types = game.get_all_possible_challenge_types()
	
	# Start the game for all players
	var params = {'airlines': airlines, 'challenge_types': c_types}
		
	if current_round == 0:
		params['show_tutorial'] = true
		num_tutorial_finished = 0
	
	else:
		params['show_tutorial'] = false
	
	var all_people = game.get_all_people()
	for i in range(num_players):
		var p = params.duplicate(true)
		p['people'] = all_people[i]
		rpc_id(player_ids[i], 'start_game', p)
	
	if not params['show_tutorial']:
		send_first_challenges()
	
	var t = Time.get_time_dict_from_system()
	t = str(t['hour']) + ':' + str(t['minute']) + ':' + str(t['second'])
	print('Airport:' + str(host_id) + ', num_players: ' + str(num_players) + ', round: ' + str(current_round) + ', time: ' + t)

remote func finish_tutorial():
	num_tutorial_finished += 1
	if num_tutorial_finished >= num_players:
		rpc('hide_tutorial')
		send_first_challenges()

func send_first_challenges():
	for i in range(config.challenge_simultaneous[num_players]):
		var challenge = game.next_challenge()
		if not challenge:
			print('Missing challenge!')
			break
		
		var player = challenge[3]['player']
		rpc_id(player_ids[player], 'add_challenge', challenge)

func get_players():
	var players = []
	for p in get_children():
		if not p.has_method("generate_person"):
			players.append(p)
	return players

func swap_people(p_id, swaps, success=false):
	rpc_id(player_ids[p_id], 'swap_people', swaps, success)

remote func select_person(p_id, category):
	var caller_id = get_tree().get_rpc_sender_id()
	var success = game.person_selected(p_id, category)

	if not success:
		rpc_id(caller_id, 'fail_person', p_id)
		return

	rpc_id(caller_id, 'swap_people', [success['swap']], true)

	if success['completed'] != -1:
		rpc_id(player_ids[success['completed']], 'remove_challenge')
			
		var challenge = game.next_challenge()
		if challenge:
			var player_id = challenge[3]['player']
			rpc_id(player_ids[player_id], 'add_challenge', challenge)

func notify_last_call():
	rpc("last_call")

func notify_throttle():
	rpc("throttle")

remote func click_throttle():
	game.click_throttle()

func finish_round(statistics):
	var improvements = {'fails': 0, 'time': 0, 'throttle': 0}
	if last_statistics:
		var ls = last_statistics
		improvements['fails'] = sign((ls['fail_person'] + ls['fail_challenge']) - (statistics['fail_person'] + statistics['fail_challenge']))
		improvements['time'] = sign(ls['time'] - statistics['time'])
		improvements['throttle'] = sign(ls['throttle'] - statistics['throttle'])
	
	last_statistics = statistics
	statistics['improvements'] = improvements
	current_round += 1
	current_statistics = statistics
	
	round_end_delay = 0.0
	round_ended = true
	set_process(true)

func _process(delta):
	if round_ended:
		round_end_delay += delta
		if round_end_delay >= 2.0:
			rpc("finish_round", current_statistics)
			set_process(false)
			round_ended = false

remote func next_round():
	var caller_id = get_tree().get_rpc_sender_id()
	if caller_id == host_id:
		start_next_round()
		
remote func replay():
	var caller_id = get_tree().get_rpc_sender_id()
	if caller_id == host_id:
		current_round -= 1
		start_next_round()
		
remote func challenge_timeout():
	var caller_id = get_tree().get_rpc_sender_id()
	game.challenge_timeout()
	rpc_id(caller_id, "fail_challenge")
