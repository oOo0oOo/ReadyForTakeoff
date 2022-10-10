extends Node

var room_template
var game_template
var challenge_params = ['destination', 'seat_row', 'seat_letter', 'luggage', 'shirt', 'glasses', 'hair']

func _ready():
	room_template = load("res://Room.tscn")
	game_template = load("res://Game.tscn")
	
	test_setup()
	test_single_variable_challenge()
	test_fuzzy_challenge()

	test_generate_challenge()
	test_generate_challenge_setup()

	test_new_challenge_for_player()
	test_person_selected()

	print('Finished all tests')
	get_tree().quit()


func setup_test_room(num_pla=8, num_people_per_player=8, num_destinations=3, num_image_cat=3, num_image_options=10, add_challenges=true):
	var room = room_template.instance()
	
	for i in range(num_pla):
		room.add_player(randi())
	room.start_game(true)
	
	return room.game

func setup_test_game(num_players=8, add_challenges=true, round_num=0):
	for c in get_children():
		c.queue_free()
	
	var game = game_template.instance()
	game.setup(self, num_players, round_num, add_challenges)
	add_child(game)
	return game

# This gets called from the game (we pretend to be the room)
func swap_people(p_id, swaps, success=false):
	pass
#	print("ROOM: swap for player ", p_id, ' ', swaps)

func notify_last_call():
	pass

func notify_throttle():
	pass
	
func finish_round(stats):
	pass

func assertEqual(a, b, msg):
	if a != b:
		print(msg, ': ', a, ' != ', b)

func assertTrue(a, msg):
	if !a:
		print(msg, '  ', a, ' != True')

		
func challenge_possible(challenge, algo):
	challenge = challenge.duplicate(true)
	var options = challenge[0]
	var solution = challenge[1]
	var swaps = challenge[2]
	var meta = challenge[3]
	
	solution.sort()
	
	var people = algo.get_universe()
	
	assertTrue(len(solution) > 0, 'No solution for challenge!' + str(challenge))

	# Check swaps
	var to_remove = []
	for player_id in swaps.keys():
		var p_swaps = swaps[player_id]
		for swap in p_swaps:
			var p_out = swap[0]
			var p_in = swap[1]
			var person = swap[2]
			
			assertEqual(player_id, person['player'], 'Incorrect swap in challenge: player in')
			if p_out in people:
				assertEqual(player_id, people[p_out]['player'], 'Incorrect swap in challenge: player out')
			else:
				print('Incorrect swap, cannot remove p_out ' + str(p_out) + '\n' + str(challenge))
			to_remove.append(p_out)
			if p_in in solution:
				assertTrue(person['reserved'], 'Incorrect swap in challenge: player not reserved')
				solution.erase(p_in)
				
			# Check if swap collides with any other challenges
			for other in algo.challenge_queue:
				var arr1 = other[1].duplicate(true)
				arr1.sort()
				if arr1 == solution:
					continue
					
				if other[1].has(p_out) or other[1].has(p_in):
					print('Incorrect swap: person used in other challenge!')
			
				for other_sw in other[2].values():
					for sw in other_sw:
						if sw[0] == p_out:
							print('Incorrect swap: Another swap removes p_out??')
						elif sw[0] == p_in:
							print('Incorrect swap: Another swap removes p_in??')
						elif sw[1] == p_out:
							pass
#							print('Incorrect swap: Another swap adds p_out??')
						elif sw[1] == p_in:
							print('Incorrect swap: Another swap adds p_in??')
							

	# Check all people if they match
	for p_id in people.keys():
		var person = people[p_id]
		var matched = false
		var ok = false
		for attr in options.keys():
			if attr != 'seat':
				var option = options[attr]
				if person[attr] != option:
					ok = true
					break
				
		if not ok:
			# Found a person that matches
			if p_id in solution:
				solution.erase(p_id)
			elif p_id in to_remove:
				pass
			else:
				print('Person should be removed or in solution! ', p_id, ' ')
				return p_id
			matched = true

		if not matched:
			if p_id in solution:
				print('Person should be in the solution!')

	assertEqual(len(solution), 0, 'Elements remaining in solution')
	
	return -1

func implementation_correct(ch, algo):
	ch = ch.duplicate(true)
	var universe = algo.get_universe()
	for player_id in ch[2].keys():
		var swaps = ch[2][player_id]
		for swap in swaps:
			# Find in queue
			var found = false
			for t_swap in algo.queue[player_id]:
				if t_swap[0] == swap[0]:
					found = true
					break
			
			if not found:
				print("Incorrect swap implementation")
				
			assertTrue(universe[swap[0]]['reserved'], 'Person should be reserved, removing ' + str(swap[0]))

			if not universe[swap[0]]['reserved']:
				print(swap[0], universe[swap[0]], '  out person ', algo.people.has(swap[0]))

	# Also check if all solution people are reserved
	for p_id in ch[1]:
		assertTrue(universe[p_id]['reserved'], 'Person should be reserved, solution')


func challenge_ready(ch, algo):
	var solution = ch[1].duplicate(true)
	solution.sort()
	assertTrue(len(ch[1]) > 0, 'No solution for challenge!' + str(ch))
	for p_id in ch[1]:
		if not p_id in algo.people.keys():
			if p_id in algo.get_universe().keys():
				print('Challenge not ready: person not swapped in yet')
			else:
				print('Challenge not ready: person missing! ', algo.num_players)
	
	for p_id in algo.people.keys():
		var person = algo.people[p_id]
		var ok = false
		for attr in ch[0].keys():
			if attr != 'seat':
				var option = ch[0][attr]
				if person[attr] != option:
					# Found a not matching person
					assertTrue(!(p_id in ch[1]), 'Challenge wrong! Person should not be in solution! ' + str(person) + '\n' + str(ch))
					ok = true
					break
			
		if not ok:
			# Found a person
			assertTrue((p_id in ch[1]), 'Challenge wrong! Person should be in solution or removed! num players ' + str(algo.num_players) + '  ' + str(p_id) + '  ' + str(person))
			
			if not p_id in ch[1]:
				if p_id in algo.get_universe().keys():
					print('Reason: Swap has not happened yet')
				else:
					print('Reason: Missing swap!')
					
	# Check if removing the solutions would disable another challenge
	for other in algo.challenge_queue:
		var arr1 = other[1].duplicate(true)
		arr1.sort()
		if arr1 == solution:
			continue
		
		for sol in solution:
			if other[1].has(sol):
				print('Challenge wrong! Removing this would interfere with the solution of another challenge!')
	
func test_setup():
	for num_players in range(1, config.MAX_PLAYERS + 1):
		var algo = setup_test_game(num_players, false)
		# Check if people are correct
		assertEqual(algo.num_players, num_players, 'incorrect number of players')
		assertEqual(len(algo.people), 8 * num_players, 'incorrect number of people')


func test_single_variable_challenge():
	var fails = {}
	for i in challenge_params:
		fails[i] = 0
		
	for variable in challenge_params:
		for num_players in range(1, config.MAX_PLAYERS + 1):
			for max_players in range(1, num_players + 1):
				for max_people_per_player in range(1, 9):
					var algo = setup_test_game(num_players, false)
					var options = [{}, [variable], max_players, max_people_per_player] # Fixed, forbidden, variables, max_players, max_people_per_player
					var challenge = algo.find_challenge(options)
					if not challenge:
						fails[variable] = max(fails[variable], max_people_per_player)
					else:
						# Check if the challenges is possible
						challenge_possible(challenge, algo)
						assertEqual(challenge[0].keys(), [variable], 'Incorrect challenge')
					
						algo.implement_challenge(challenge)
						implementation_correct(challenge, algo)

	print('Single variable fails for max_people_per_player <=')
	print(fails)


func test_fuzzy_challenge():
	var num = 500
	var fails = []

	print('Testing fuzzy challenges')
	for i in range(num):
		var num_players = utils.randrange(1, config.MAX_PLAYERS + 1)
		var max_players = utils.randrange(1, num_players + 1)
		var max_people_per_player = utils.randrange(1, 9)

		var algo = setup_test_game(num_players, false)

		var num_var = utils.randrange(1, 3)
		var num_fixed = utils.randrange(0, 3)

		var par = challenge_params.duplicate(true)
		par.shuffle()

		# We know that a single variable just doesnt work for destination and luggage
		if num_fixed == 0:
			while par[0] in ['destination', 'luggage', 'seat_letter']:
				par.shuffle()

		var variables = par.slice(0, num_var - 1)
		var fixed_params = par.slice(num_var, num_var + num_fixed - 1)
		
		var fixed = {}
		for p in fixed_params:
			fixed[p] = utils.choice(algo.branch_options[p])
		
#		var before = OS.get_ticks_msec()
		var ch = algo.find_challenge([fixed, variables, max_players, max_people_per_player])
#		print(int(OS.get_ticks_msec() - before))
		
		if ch:
			assertTrue(len(ch[1]) > 0, 'No solution in challenge')
			var success = challenge_possible(ch.duplicate(true), algo)
			algo.implement_challenge(ch)
			implementation_correct(ch, algo)
		else:
			fails.append([num_players, variables, fixed_params, max_players, max_people_per_player])
	
	print("Fails: ", len(fails), ' / ', num)


func test_generate_challenge():
	var c_types = ['boarding_row', 
		#'boarding_last_call',
		'boarding_window', 'boarding_first',
		'check_in', 'check_in_row', 'check_in_first',
		'info_seat', 'info_parent', 'info_first',
		'info_seat_complete',
		# 'info_delayed', 
		'lost_and_found', 'lost_and_found_only_seat',
		'police', 'police_row', 'police_destination',
		'vip', 'vip_multi', 'vip_two', 'police_two', 'vip_three', 'police_three']

	print('Testing the preset types of challenges.\nGenerate one challenge for each player.')
	for c_type in c_types:
		for num_players in range(1, config.MAX_PLAYERS + 1):
			var fails = []
			for i in range(4):
				fails.append(0)
				var algo = setup_test_game(num_players, false)

				# Generate one for each player
				for j in range(num_players + 1):
					var ch = algo.generate_challenge(c_type)
					if ch:
						challenge_possible(ch, algo)
						algo.implement_challenge(ch)
						implementation_correct(ch, algo)
						
						# No glasses not allowed
						var options = ch[0]
						if 'glasses' in options:
							assertTrue(options['glasses'] != 0, 'No glasses is not a valid request')
						
						# Gender is required for all image challenges
						if 'glasses' in options or 'shirt' in options or 'hair' in options:
							assertTrue('gender' in options, 'Gender is required for valid image challenge:' + str(ch))
							
					else:
						fails[i] += 1
			
			for f in fails:
				if f > 0:
					print(c_type, ' fails with ', num_players, ' players: ', fails)
					break
				

func test_generate_challenge_setup():
	for num_players in range(1, config.MAX_PLAYERS + 1):
		for i in range(10):
			var algo = setup_test_game(num_players, true)
			
			for player_id in range(num_players):
				assertTrue(len(algo.queue[player_id]) == 0, 'Queues should be empty initially')

			assertTrue(config.challenge_simultaneous[num_players] <= len(algo.challenge_queue), 'Not enough challenges for each player!!')

			for ch in algo.challenge_queue:
				challenge_ready(ch, algo)

			for i in range(5):
				var ch = algo.generate_challenge()

				if ch:
					challenge_possible(ch, algo)
					algo.implement_challenge(ch)
					implementation_correct(ch, algo)


func test_new_challenge_for_player():
	print('Test generating new challenge for player')
	for num_players in range(1, config.MAX_PLAYERS + 1):
		for i in range(0, 40):
			var algo = setup_test_game(num_players, true, i)
			var fails = 0
			for player_id in range(num_players):
				var ch = algo.new_challenge_for_player(player_id)
				if not ch:
					fails += 1
					continue
					
				challenge_ready(ch, algo)
				
				assertEqual(ch[3]['player'], player_id, 'challenge has wrong player!')
				assertEqual(ch[3]['found'], [], 'Challenge found is not empty!')
				assertTrue(len(ch[1]) > 0, 'No solution for challenge! ' + str(ch))
			
			if fails > 0:
				print('Missing ', str(fails), ' players at start (everyone starts with one challenge) in round ', str(i), ' and ', str(num_players), ' players')


func test_person_selected():
	print('Test person selected / full test')
	for num_players in range(1, config.MAX_PLAYERS + 1):
		for round_num in range(30):
			var algo = setup_test_game(num_players, true, round_num)
			
			var current_challenges = {}
			for i in range(config.challenge_simultaneous[num_players]):
				var challenge = algo.next_challenge()
				if challenge:
					var player_id = challenge[3]['player']
					current_challenges[player_id] = challenge
			
			for n_chal in range(20):
				# Pick a random player
				var player_id = utils.choice(current_challenges.keys())
				
				var ch = current_challenges[player_id].duplicate(true)
				current_challenges.erase(player_id)
				
				if not ch:
					print('No challenge available in test.')
					continue
				
#				print("Fulfill challenge ready?")
				challenge_ready(ch, algo)
				
				# Fulfill challenge
				var c_type = ch[3]['type']
				var cat
				for c in ['info', 'boarding', 'check_in', 'lost_and_found', 'police', 'vip']:
					if c_type.begins_with(c):
						cat = c
						break
				
				for i in range(len(ch[1])):
					var len_expected = len(algo.challenge_queue) - 1
					var p_id = ch[1][i]
					# Wrong cat
					var wrong = ['info', 'boarding', 'check_in', 'lost_and_found', 'police', 'vip']
					wrong.erase(cat)
					wrong = utils.choice(wrong)
					assertEqual(algo.person_selected(p_id, wrong), false, 'Person should be wrong, when selected! (category)')

					# Wrong id
					for p in range(5):
						assertEqual(algo.person_selected(utils.rand_id(), cat), false, 'Person should be wrong, when selected! (id)')

					# Correct
					var ret = algo.person_selected(p_id, cat)
					
					assertTrue(typeof(ret) != 1, 'Person should be selected!')

#					print('Clicked ', p_id, ret)
					# Last one should give finished player
					if i == len(ch[1]) - 1:
						assertEqual(ret['completed'], ch[3]['player'], 'Challenge did not finish correctly!' + str(ch))
						
						assertEqual(len(algo.challenge_queue), len_expected, 'Challenge was not removed from queue!')
						
						for ch in algo.challenge_queue:
							if ch[3]['player'] == player_id:
								print('Remaining challenge for player!!', player_id)
						
					else:
						assertEqual(ret['completed'], -1, 'Person did not get accepted!')
					
					# Check the swap
					assertEqual(ret.keys(), ['completed', 'swap'], 'Challenge did not finish correctly! keys')
					assertEqual(ret['swap'][0], p_id, 'Incorrect swap person selected!')
					
					
				
				# Get a new challenge
#				print('I want a new challenge for player ', player_id)
				var new_ch = algo.next_challenge()

				if new_ch:
					player_id = new_ch[3]['player']

					var num = 0
					for ch in algo.challenge_queue:
						if ch[3]['player'] == player_id:
							num += 1
					if num > 1:
						print('Player has more than one challenge!!')
#					assertEqual(new_ch[3]['player'], player_id, 'Incorrect player for challenge!')
					current_challenges[player_id] = new_ch.duplicate(true)
					# This challenge is typically ready! The other check sometimes failes (above) ;(
					challenge_ready(new_ch, algo)
				else:
					print('no follow up challenge!! Num players: ', num_players, ', Round ', round_num , ', chal num ', n_chal)
					print('num challenges in queue', len(algo.challenge_queue))
