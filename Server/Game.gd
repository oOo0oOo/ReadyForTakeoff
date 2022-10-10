extends Node

const DESTINATIONS = ['Amsterdam', 'Anchorage', 'Antalya', 'Athens', 'Atlanta', 'Auckland', 'Baltimore', 'Bangkok', 'Barcelona', 'Beijing', 'Beirut', 'Berlin', 'Bogota', 'Boston', 'Brasilia', 'Brisbane', 'Brussels', 'Budapest', 'Cairo', 'Caracas', 'Charlotte', 'Chengdu', 'Chennai', 'Chicago', 'Dakar', 'Dallas', 'Damascus', 'Denver', 'Detroit', 'Doha', 'Dubai', 'Dublin', 'Fiji', 'Frankfurt', 'Fukuoka', 'Guangzhou', 'Hangzhou', 'Hanoi', 'Havana', 'Helsinki', 'Hong Kong', 'Houston', 'Istanbul', 'Jakarta', 'Jeddah', 'Jeju', 'Kathmandu', 'Kinshasa', 'Kiribati', 'Kunming', 'La Paz', 'Lagos', 'Las Vegas', 'Lhasa', 'Lima', 'Lisbon', 'London', 'Madrid', 'Manado', 'Mandalay', 'Manila', 'Melbourne', 'Mendoza', 'Miami', 'Milan', 'Montreal', 'Moscow', 'Mumbai', 'Munich', 'Muscat', 'Nagoya', 'Nairobi', 'Naples', 'New Delhi', 'New York', 'Newark', 'Orlando', 'Oslo', 'Paris', 'Phoenix', 'Phuket', 'Quito', 'Reykjavik', 'Riyadh', 'Rome', 'San Diego', 'Sao Paulo', 'Sapporo', 'Seattle', 'Seoul', 'Shanghai', 'Shenzhen', 'Singapore', 'Stockholm', 'Surabaya', 'Sydney', 'Taipei', 'Tampa', 'Tehran', 'Tel Aviv', 'Tenerife', 'Tokyo', 'Toronto', 'Vancouver', 'Venice', 'Vienna', 'Vilnius', 'Xiamen', 'Yerevan', 'Zanzibar', 'Zurich']
const SPACE_DESTINATIONS = ['Ceres', 'Jupiter', 'Mars', 'Mercury', 'Moon', 'Neptune', 'Pluto', 'Saturn', 'Uranus', 'Venus', 'Sun']
const SEAT_LETTERS = ['A', 'B', 'C', 'D'] # ['window', 'aisle']


const NUM_TRIES_CHALLENGE = 3 # This is deceiving because we first try this amount of time to generate the exact challenge type and if not possible we randomly try any challenge type this amount of times

var MAX_TRIES_COMBINATIONS = 350
const MAX_CHANGES_PER_PLAYER_PER_CHALLENGE = 3

var room
var num_players
var num_image_categories
var branch_options
var max_changes_per_challenge

var challenge_queue
var queue
var people
var current_challenges
var current_config
var orig_config
var current_round
var num_challenges_generated
var num_challenges_completed

var img_weighted = []
# No glasses (0) is common
const glasses_weighted = [0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5]

var statistics

var next_player

var throttle_times = []

func _ready():
	randomize()

func setup(room_inst, num_player, cur_round, add_challenges=true):
	current_round = cur_round
	room = room_inst # The room is used to send out messages
	num_players = num_player
	
	var num_destinations = 3 
	var num_people_per_player = 8
	num_challenges_generated = 0
	num_challenges_completed = 0
	
	throttle_times = []
	
	next_player = []
	for i in range(40):
		var players = range(num_players)
		players.shuffle()
		for p in players:
			next_player.append(p)
	
	statistics = {
		'time': OS.get_ticks_msec(),
		'fail_person': 0,
		'fail_challenge': 0
	}
	
	# Get the currently valid configuration
	var phase = int(current_round / config.NUM_ROUNDS_PER_PHASE)
	phase = min(phase, len(config.airport_phase) - 1)
	current_config = config.airport_phase[phase].duplicate(true)
	orig_config = current_config.duplicate(true)
	
	# Space port has different config
	var dest
	if phase == len(config.airport_phase) - 1:
		dest = utils.sample(SPACE_DESTINATIONS, 2)
		dest.append(utils.choice(DESTINATIONS))
	else:
		dest = utils.sample(DESTINATIONS, 3)
		
	branch_options = {
		'destination': dest,
		'seat_row': range(1, 6),
		'seat_letter': SEAT_LETTERS,
		'luggage': range(3),
		'player': range(num_players),
		'reserved': [false],
		'gender': ['male', 'female'],
		'shirt': range(21),
		'glasses': range(1, 6),
		'hair': range(11)
	}
	
	# Create list of image categories weighted by how many options they have
	for type in ['shirt', 'glasses', 'hair']:
		for i in range(len(branch_options[type])):
			img_weighted.append(type)

#	for i in range(num_image_categories):
#		branch_options['image_' + str(i)] = range(num_image_options)

	max_changes_per_challenge = int(ceil(num_players * 1.25))

	people = {}
	challenge_queue = []
	queue = {}
	for i in range(num_players):
		queue[i] = []

	# Add the initial people to the players
	for i in range(num_players):
		for p in range(num_people_per_player):
			var person = generate_person({'player': i})
			people[utils.rand_id()] = person

	# Work ahead a bit, prepare some challenges
	if add_challenges:
		var count = 0
		while challenge_queue.size() < max(num_players, 4):
			var challenge = generate_challenge()
			
			if challenge:
				implement_challenge(challenge, false)
#
			count += 1
			if count >= 20:
				print('Too few initial challenges found: ', str(challenge_queue.size()), '/', str(num_players))
				break

func get_all_people():
	# Sorted per player
	var sorted = []
	for p in range(num_players):
		sorted.append({})
	
	for p_id in people.keys():
		var person = people[p_id]
		sorted[person['player']][p_id] = person
	return sorted

func generate_person(data=false):
	var person = {}
	if not data:
		data = {}

	for option in branch_options.keys():
		var v
		# Glasses are picked from a weighted list (no glasses are more common)
		if option == 'glasses':
			v = data.get(option, utils.choice(glasses_weighted))
		else:
			v = data.get(option, utils.choice(branch_options[option]))
		person[option] = v
	
	person['seat'] = str(person['seat_row']) + str(utils.randrange(0, 10)) + person['seat_letter']
	return person

func generate_challenge(challenge_type=false):
	
	var c_type
	if not challenge_type:
		c_type = utils.choice(current_config['challenge_types'])
	else:
		c_type = challenge_type
		
#	print('Generating challenge type: ', c_type)
	var real_c_types = ['boarding', 'check_in', 'info', 'lost_and_found', 'police', 'vip']
	var success = false
	var challenge = false
	var options
	for i in range(NUM_TRIES_CHALLENGE):
		options = get_challenge_options(c_type)
		challenge = find_challenge(options)
		if challenge:
			break

	# Cannot generate this challenge at the moment..
	# Try a filler (all except boarding and check in)
	if not challenge:
		for i in range(NUM_TRIES_CHALLENGE):
			c_type = utils.choice(current_config['challenge_types'])
	
			options = get_challenge_options(c_type)
			challenge = find_challenge(options)
			if challenge:
				break
	
	if challenge:
		for real in real_c_types:
			if c_type.begins_with(real):
				challenge[3]['type'] = real
				break
		
		# Is this a timed challenge
		challenge[3]['time'] = -1
		if current_config['challenge_timed'].has(c_type):
			if randf() <= current_config['challenge_timed'][c_type]:
				challenge[3]['time'] = current_config['challenge_time']
		
		# Switch to last call parameters after enough normal challenges happened
		num_challenges_generated += 1
		var lc = config.last_call
		if num_challenges_generated == current_config['normal_challenges']:
			# Add extra types and update probability of timed event
			for ch in lc['challenge_types']:
				current_config['challenge_types'].append(ch)
			
			for ch in lc['challenge_timed'].keys():
				current_config['challenge_timed'][ch] = lc['challenge_timed'][ch]
				
			# Remove all check ins
			for ch_type in current_config['challenge_types'].duplicate(true):
				if ch_type.begins_with('check_in'):
					current_config['challenge_types'].erase(ch_type)
	
#	else:
#		print('No challenge found, last try: ', str(options))
	return challenge

func rand_option(param):
	return utils.choice(branch_options[param])
	
func rand_img_option():
	return utils.choice(img_weighted)

func get_challenge_options(c_type):
	##
	## Boarding
	##
	var options
	var img
	if c_type == 'boarding_row':
		options = [
			{},
			['destination', 'seat_row'], 2, 2]

	elif c_type == 'boarding_last_call':
		options = [{}, ['destination'], num_players, 2]

	# Boarding window, aisle
	elif c_type == 'boarding_window':
		options = [{}, ['destination', 'seat_letter'], 2, 2]

	# Preferrential boarding
	elif c_type == 'boarding_first':
		options = [{'seat_row': utils.randrange(1, 3)}, ['destination'], 2, 2]

	##
	## Check in
	##
	elif c_type == 'check_in':
		options = [{}, ['destination', 'luggage'], num_players, 2]

	elif c_type == 'check_in_row':
		options = [{}, ['luggage', 'seat_row'], 2, 2]

	# First class check in, business class check in
	elif c_type == 'check_in_first':
		options = [{'seat_row': utils.randrange(1, 3)}, ['destination', 'luggage'], 2, 2]

	# All oversized: luggage == 3

	##
	## Info
	##
	elif c_type == 'info_seat':
		options = [{}, ['destination', 'seat_row'], 1, 1]
	
	elif c_type == 'info_seat_complete':
		options = [{}, ['seat_row', 'seat_letter'], 1, 1]


	elif c_type == 'info_delayed':
		options = [{}, ['destination'], num_players, 2]

	# Missing parent! destination, image
	elif c_type == 'info_parent':
		img = rand_img_option()
		options = [{}, ['destination', img, 'gender'], 1, 1]

	# First Class Lounge: seat row = 1
	# Business class Buffet: seat row 2 or 3
	elif c_type == 'info_first':
		options = [{'seat_row': utils.randrange(1, 3)}, ['destination'], 2, 2]

	##
	## Lost and found
	##
	elif c_type == 'lost_and_found_only_seat':
		options = [{}, ['seat_row', 'seat_letter'], 1, 1]

	elif c_type == 'lost_and_found':
		options = [{'luggage': utils.randrange(1, 3)}, ['seat_row', 'seat_letter'], 1, 1]

	##
	## Police
	##
	elif c_type == 'police':
		img = rand_img_option()
		options = [{}, [img, 'gender'], 1, 1]

	# image & seat_row
	elif c_type == 'police_row':
		img = rand_img_option()
		options = [{}, [img, 'seat_row', 'gender'], 1, 1]

	elif c_type == 'police_destination':
		img = rand_img_option()
		options = [{}, [img, 'destination', 'gender'], 1, 1]
	
	elif c_type == 'police_two':
		var opt = utils.choice([['hair', 'glasses'], ['glasses', 'shirt'], ['shirt', 'hair']])
		opt.append('gender')
		options = [{}, opt, 2, 1]
	
	elif c_type == 'police_three':
		options = [{}, ['shirt', 'hair', 'glasses', 'gender'], 1, 1]
		
	##
	## VIP
	##
	elif c_type == 'vip':
		img = rand_img_option()
		options = [{}, [img, 'gender'], 1, 1]

	# Img & destination
	elif c_type == 'vip_multi':
		img = rand_img_option()
		options = [{}, [img, 'gender'], 2, 2]
	
	elif c_type == 'vip_two':
		var opt = utils.choice([['hair', 'glasses'], ['glasses', 'shirt'], ['shirt', 'hair']])
		opt.append('gender')
		options = [{}, opt, 1, 1]
	
	elif c_type == 'vip_three':
		options = [{}, ['shirt', 'hair', 'glasses', 'gender'], 1, 1]

	return options

func compare_first(a, b):
	return a[0] > b[0]
	

func get_universe():
	# We have to construct an expanded universe of super heroes to check.
	# Not only the "people" on earth but also the future generation to be born.
	var universe = people.duplicate(true)
	for swaps in queue.values():
		for swap in swaps:
			universe[swap[1]] = swap[2].duplicate(true)
	return universe


func find_challenge(challenge_options):
	var fixed = challenge_options[0]
	var variables = challenge_options[1]
	var max_players = challenge_options[2]
	var max_people_per_player = challenge_options[3]
	
	# Collect candidates that fit the fixed parameters
	var found = []
	var avoid = []
	
	var universe = get_universe()

	for p_id in universe.keys():
		var person = universe[p_id]
		var identical = true
		for option in fixed.keys():
			var value = fixed[option]
			if person[option] != value:
				identical = false
				break
		
		if identical:
			# Check if reserved person
			if person['reserved']:
				avoid.append(p_id)
			else:
				found.append(p_id)
	
	# Find all possible combinations of variables given the variables (MAX 4!)
	var combinations = []
	for opt0 in branch_options[variables[0]]:
		if variables.size() == 1:
			combinations.append({variables[0]: opt0})
		else:
			for opt1 in branch_options[variables[1]]:
				if variables.size() == 2:
					combinations.append({variables[0]: opt0, variables[1]: opt1})
				else:
					for opt2 in branch_options[variables[2]]:
						if variables.size() == 3:
							combinations.append({variables[0]: opt0, variables[1]: opt1, variables[2]: opt2})
						else:
							for opt3 in branch_options[variables[3]]:
								combinations.append({variables[0]: opt0, variables[1]: opt1, variables[2]: opt2, variables[3]: opt3})
								
	
	combinations.shuffle()
	
	if len(combinations) > MAX_TRIES_COMBINATIONS:
		combinations = combinations.slice(0, MAX_TRIES_COMBINATIONS - 1)
	
#	print('Find challenge: Trying combinations ', len(combinations), ' ', str(challenge_options))

	# Test all possible combinations, key is if the challenge can be implemented and how much would need to be changed
	var challenges = []
	var try = 0

	for options in combinations:
		try += 1
		# Check if any of the avoids have this combination = bad
		var abort = false
		for p_id in avoid:
			var person = universe[p_id]
			var ok = false
			for param in options.keys():
				var value = options[param]
				if person[param] != value:
					ok = true
					break
			if not ok:
				abort = true
				break

		if abort:
			continue

		# Check if we have matching people with this combo
		var matching_per_player = {}
		for p_id in found:
			var person = universe[p_id]
			var ok = false
			for param in options.keys():
				var value = options[param]
				if person[param] != value:
					ok = true
					break
			
			if not ok:
#				matching.append(p_id)
				if matching_per_player.has(person['player']):
					matching_per_player[person['player']].append(p_id)
				else:
					matching_per_player[person['player']] = [p_id]

		# Add and remove people, to stay within the max number of players and people per player
		# Too many players = remove those with the least friction (= least people that match)
		var friction = []
		for p_id in matching_per_player.keys():
			friction.append([matching_per_player[p_id].size(), p_id])
		friction.sort_custom(self, 'compare_first')
		
#		var friction = sorted(matching_per_player.items(), key=lambda x: len(x[1]), reverse=True)

		# (Which players get removed) which people get removed
		var to_remove = []
		
		var change_count = 0
		for i in range(len(friction)):
			var player_id = friction[i][1]
			var p_ids = matching_per_player[player_id]
			var p_ids_remove = []

			# Remove a whole player (too many players)
			if i >= max_players:
				change_count += len(p_ids)
				p_ids_remove = p_ids

			# Remove some people to stay within max people per player bound
			elif len(p_ids) > max_people_per_player:
				change_count += len(p_ids) - max_people_per_player
				p_ids_remove = p_ids.slice(max_people_per_player - 1, p_ids.size() - 1)

			# Have we already gone too far?
			if change_count > max_changes_per_challenge:
				abort = true
				break
			
			elif len(p_ids_remove) > MAX_CHANGES_PER_PLAYER_PER_CHALLENGE:
				abort = true
				break

			# Just do it
			for p_id in p_ids_remove:
				to_remove.append(p_id)
				matching_per_player[player_id].erase(p_id)
			
			if len(matching_per_player[player_id]) == 0:
				matching_per_player.erase(player_id)

		if abort:
			continue

		# Now we need to add players according to max_players
		# If 1 player: force 1 player
		# If 2 players: force 2 players
		# If 3+ players: at least 3 players
#		for player_id in matching_per_player.keys():
#			if matching_per_player[player_id].size() == 0:
#				matching_per_player.erase(player_id)
		
		var to_add = {}
		
		var players_to_add = min(max_players, 3) - len(matching_per_player)
		if players_to_add > 0:
			players_to_add = min(players_to_add, num_players - len(matching_per_player))

			# Check remaining players if it is possible to remove a person = we can also add one
			var players = []
			for p in range(num_players):
				if not matching_per_player.keys().has(p):
					players.append(p)
			players.shuffle()
	
			var success = false
			for player_id in players:
				# Check if we can remove a person from this player
				# This goes for people directly and not the whole universe!
				var remove_id = false
				for p_id in people.keys():
					var person = people[p_id] 
					if person['player'] == player_id:
						if not person['reserved']:
							if not to_remove.has(p_id):
								remove_id = p_id
								break

				if not remove_id:
					continue

				# Do it
				to_remove.append(remove_id)
				matching_per_player[player_id] = []
				players_to_add -= 1

				if len(to_remove) > max_changes_per_challenge:
					abort = true
					break

				# Found enough people
				if players_to_add == 0:
					success = true
					break

			if not success:
				# Not a valid solution because we could not find a suited player to add
				abort = true

			if abort:
				continue

			# Now finally we can add one new person if needed
			for player_id in matching_per_player.keys():
				var p_ids = matching_per_player[player_id]
				if not p_ids:
					var data = fixed.duplicate()
					for k in options.keys():
						data[k] = options[k]
						
					data['player'] = player_id
					data['reserved'] = true
					var ind = utils.rand_id()
	
					var person
					var ok = false
					for i in range(8):
						person = generate_person(data)
						if not collides_with_challenges(person):
							var bad = false
							# Check if it collides with another person to add
							for other in to_add.values():
								var same = true
								for opt in other.keys():
									if not ['gender', 'reserved', 'seat', 'player'].has(opt):
										if person[opt] != other[opt]:
											same = false
											break
								if same:
									bad = true
									break
									
							if not bad:
								ok = true
								break
								
					if not ok:
						abort = true
						break

					to_add[ind] = person
					matching_per_player[player_id] = [ind]
				
				# We can also check if too many changes per player
				else:
					if len(p_ids) > MAX_CHANGES_PER_PLAYER_PER_CHALLENGE:
						abort = true
						break
						
			if abort:
				continue

		# The solution (all matches)
		var solution = []
		for p in matching_per_player.values():
			for p_id in p:
				solution.append(p_id)
				
		# We will pick the option with the least to remove and add
		challenges.append([len(to_remove), options, solution, to_remove, to_add])

		# Immediately accept challenges with 0 changes
		if len(to_remove) == 0:
			break
		
		var stop = 1.1 * num_players * try / MAX_TRIES_COMBINATIONS
		if len(to_remove) <= stop:
			break

	if not challenges:
#		print('Find challenge bad: Not a single candidate found!!')
#		print(challenge_options, '  num players ', num_players)
		return false
	
	challenges.sort_custom(self, 'compare_first')
	var challenge = challenges[0]
	var num_changes = challenge[0]
	var options = challenge[1]
	var solution = challenge[2]
	var to_remove = challenge[3]
	var to_add = challenge[4]

	if num_changes > max_changes_per_challenge:
#		print('Find challenge bad: Too many changes in the selected challenge??')
		return false

	# Create the queues
	var p_in_queue = {}
	var p_out_queue = {}
	var swaps = {}
	
	for i in range(num_players):
		p_in_queue[i] = []
		p_out_queue[i] = []
		swaps[i] = []

	for p_id in to_remove:
		var person = universe[p_id]
		p_out_queue[person['player']].append(p_id)

	for p_id in to_add.keys():
		var person = to_add[p_id]
		p_in_queue[person['player']].append(p_id)

	var summary = fixed.duplicate()
	for opt in options.keys():
		summary[opt] = options[opt]
	
	var all_challenges = [summary.duplicate(true)]
	for c in challenge_queue:
		all_challenges.append(c[0].duplicate(true))

	for player_id in range(num_players):
		# Add new non colliding people if needed
		for i in range(len(p_out_queue[player_id]) - len(p_in_queue[player_id])):
			var data = {'player': player_id}
			var person = generate_non_colliding_person(data, all_challenges)
			if not person:
#				print('Find challenge bad: Non colliding person not found!!')
				return false

			var ind = utils.rand_id()
			to_add[ind] = person
			p_in_queue[player_id].append(ind)

		# Now match up the swaps
		for p_in in p_in_queue[player_id]:
			var p_out = p_out_queue[player_id].pop_front()
			swaps[player_id].append([p_out, p_in, to_add[p_in]])
	
	# Send exact seat in summary
	if summary.has('seat_row') and summary.has('seat_letter'):
		universe = get_universe()
		if universe.has(solution[0]):
			summary['seat'] = universe[solution[0]]['seat']
		else:
			var abort = false
			for p_swaps in swaps.values():
				for swap in p_swaps:
					if swap[1] == solution[0]:
						summary['seat'] = swap[2]['seat']
						abort = true
						break
				if abort:
					break

	return [summary, solution, swaps, {}]

func generate_non_colliding_person(data, challenges=false):
	# Try random generator
	for i in range(20):
		var person = generate_person(data)
		if not collides_with_challenges(person, challenges):
			return person

	# Now try to change a challenge slightly
	if challenge_queue:
		var opt_allowed_change = branch_options.keys()
		
		opt_allowed_change.erase('player')
		opt_allowed_change.erase('reserved')
		opt_allowed_change.erase('gender')

		var p_data = data.duplicate(true)
		var ch_opts = utils.choice(challenge_queue)[0]
		for ch in ch_opts.keys():
			p_data[ch] = ch_opts[ch]

		for i in range(20):
			var person = generate_person(p_data.duplicate())

			# Change some (1 - 3) attributes of the person
			for j in range(utils.randrange(1, 4)):
				var opt = utils.choice(opt_allowed_change)
				person[opt] = rand_option(opt)

			if not collides_with_challenges(person, challenges):
				return person

	# print("Could not generate non colliding person!")
	return false

func collides_with_challenges(person, challenges=false):
	if not challenges:
		challenges = []
		for c in challenge_queue:
			challenges.append(c[0])

	for challenge in challenges:
		var same = true
		for opt in challenge.keys():
			if !(['player', 'reserved', 'gender', 'seat'].has(opt)):
				if person[opt] != challenge[opt]:
					same = false
					break
		if same:
			return true
	
	# Check if it collides with another existing person
	var universe = get_universe()
	
	for other in universe.values():
		var same = true
		for opt in other.keys():
			if !(['player', 'reserved', 'gender', 'seat'].has(opt)):
				if person[opt] != other[opt]:
					same = false
					break
		if same:
			return true
	
	return false

func implement_challenge(challenge, use_queue=true):
	var summary = challenge[0]
	var solution = challenge[1]
	var swaps = challenge[2]
	var meta = challenge[3]

	for player in swaps.keys():
		var player_swaps = swaps[player]
		if use_queue:
			queue[player] += player_swaps
			
			# Reserve removal
			for swap in player_swaps:
				var remove_id = swap[0]
				if people.has(remove_id):
					people[remove_id]['reserved'] = true
				else:
					var ok = false
					for swps in queue.values():
						for swp in swps:
							if swp[1] == remove_id:
								swp[2]['reserved'] = true
								ok = true
								break
						if ok:
							break
							
					if not ok:
						print('Implementation: Could not find person to reserve / remove!!')
		else:
			for swap in player_swaps:
				people.erase(swap[0])
				people[swap[1]] = swap[2]
	
	# Reserve solution
	for sol in solution:
		if people.has(sol):
			people[sol]['reserved'] = true
		else:
			var ok = false
			for swps in queue.values():
				for swp in swps:
					if swp[1] == sol:
						swp[2]['reserved'] = true
						ok = true
						break
				if ok:
					break
					
			if not ok:
				print('Implementation: Could not find person to reserve!!')
		

	challenge[3]['player'] = -1
	challenge[3]['found'] = []

	challenge_queue.append(challenge)

func next_challenge():
	# Give the next challenge to the next possible player (that is free atm)
	for i in range(10):
		var player_id = next_player[i]
#		print('next challenge for player ', player_id)
		var bad = false
		for ch in challenge_queue:
			if ch[3]['player'] == player_id:
				bad = true
				break
				
		if not bad:
			var ch = new_challenge_for_player(player_id)
			next_player.remove(i)
			return ch
	return false

func new_challenge_for_player(player_id):
	# First we get some of the swaps in the queue done (for each player)
	var RATIO = 1 #1.1 / num_players # A little bit more than one part of the challenges
	for player_id in range(num_players):
		var p_queue = queue[player_id]
		if len(p_queue) > 0:
			var swaps = []
			
			# Check which swaps can be performed
			var count = 0
			for s in range(int(ceil(len(p_queue) * RATIO))):
				var swap = p_queue[count]
				if swap[0] in people.keys():
					swaps.append(swap)
					p_queue.remove(count)
				else:
					count += 1
			
			for swap in swaps:
				# Make the swap
				people[swap[1]] = swap[2].duplicate(true)
				people.erase(swap[0])

			# Also perform the swaps for the clients
			room.swap_people(player_id, swaps)
			
#	print('Selecting one challenge out of ', len(challenge_queue))
	
	# Check if player is still doing a challenge
	for ch in challenge_queue:
		if ch[3]['player'] == player_id:
			print('Player already has a challenge?? ', player_id)
			return false
	
	# Next possible challenge
	var found = false
	for i in range(len(challenge_queue)):
		var ch = challenge_queue[i]
		if ch[3]['player'] == -1:
			var ok = true
			for sol in ch[1]:
				if !(people.keys().has(sol)):
					ok = false
					break
			if ok:
				ch[3]['player'] = player_id
				found = ch.duplicate(true)
				break
	
	if found:
		# Need to generate new challenges (try to fill the queue)
		var expected = max(num_players, 4)
		var fails = 0
		var num = max(0, expected - len(challenge_queue))
#		print('Generating new challenge, num ', num, ' expected ', expected)
		for i in range(num):
			var ch = generate_challenge()
			if ch:
				implement_challenge(ch)
			else:
				fails += 1
		
		if len(challenge_queue) < expected:
			print('Challenge queue is too short! ', str(len(challenge_queue)), '/', str(expected), ', Num players: ', str(num_players), ', Round: ', str(current_round))
			print('Fails: ', str(fails))
		
	else:
		print('Why no found??')
		
	return found

func person_selected(p_id, c_cat):
	# Check if correct person
	var challenge_id = -1
	var ch_player_id = -1
	for c_id in range(len(challenge_queue)):
		var ch = challenge_queue[c_id]
		if ch[3]['player'] != -1:
			if ch[1].has(p_id):
				if c_cat == ch[3]['type']:
					challenge_id = c_id
					ch_player_id = ch[3]['player']
				break

	if challenge_id != -1:
		if challenge_queue[challenge_id][3]['found'].has(p_id):
			print('What the hell??')
			return false
			
		if !people.has(p_id):
			print('Why do you want to remove a non-existant person??')
			return false
			
		challenge_queue[challenge_id][3]['found'].append(p_id)

		# Remove the person from the player
		var player_id = people[p_id]['player']
		var ind = utils.rand_id()
		var person = generate_non_colliding_person({'player': player_id})
		if not person:
			print('Could not find non colliding person!')
			return false
		
		var swap = [p_id, ind, person.duplicate(true)]
		
		people.erase(p_id)
		people[ind] = person
		
		var ch = challenge_queue[challenge_id]
		if len(challenge_queue[challenge_id][3]['found']) == len(ch[1]):
#			print('Remove challenge for player ', challenge_queue[challenge_id][3]['player'], '  ', ch_player_id) 
			challenge_queue.remove(challenge_id)
			
			# Check if we reached last call or if we finished with the round
			num_challenges_completed += 1
			var num_normal = current_config['normal_challenges']
			if num_challenges_completed >= num_normal + current_config['last_call_challenges']:
				room.notify_throttle()
				statistics['time'] = round((OS.get_ticks_msec() - statistics['time']) / (num_challenges_completed * 100)) / 10
			elif num_challenges_completed == num_normal:
				room.notify_last_call()
			return {'completed': ch[3]['player'], 'swap': swap}
		return {'completed': -1, 'swap': swap}

	else:
		statistics['fail_person'] += 1
		return false

func get_all_possible_challenge_types():
	var real_c_types = ['boarding', 'check_in', 'info', 'lost_and_found', 'police', 'vip']
	
	var possible = []
	for c_type in orig_config['challenge_types']:
		for real in real_c_types:
			if c_type.begins_with(real):
				if not possible.has(real):
					possible.append(real)
				break
	
#	print('possible types ', possible, orig_config['challenge_types'])
	return possible

func challenge_timeout():
	statistics['fail_challenge'] += 1
	
func click_throttle():
	throttle_times.append(OS.get_ticks_msec())
	
	if len(throttle_times) == num_players:
		finish_round()

func finish_round():
	
	var next_round = float(current_round + 1) / config.NUM_ROUNDS_PER_PHASE
	
	statistics['phase'] = config.airport_phase[int(next_round)]['name']
	if int(next_round) == next_round and next_round <= len(config.airport_phase) - 1:
		statistics['phase'] = 'New Certification:\n' + statistics['phase']
		
	statistics['phase'] = statistics['phase'].capitalize()
	
	statistics['current_round'] = current_round
	
	# Throttle 
	var avg = 0.0
	for t in throttle_times:
		avg += t
	avg /= num_players
	
	var diff = 0.0
	for t in throttle_times:
		diff += abs(t - avg)
	
	statistics['throttle'] = round(diff / 10) / 100
	
	room.finish_round(statistics)
