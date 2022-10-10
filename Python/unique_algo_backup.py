from random import choice, randrange, random, shuffle
from copy import copy
from pprint import pprint
from math import ceil

destinations = ['AMSTERDAM', 'ANTALYA', 'ATHENS', 'ATLANTA', 'AUCKLAND', 'BALTIMORE', 'BANGKOK', 'BARCELONA', 'BEIJING', 'BERLIN', 'BOGOTA', 'BOSTON', 'BRASILIA', 'BRISBANE', 'BRUSSELS', 'CHARLOTTE', 'CHENGDU', 'CHICAGO', 'COPENHAGEN', 'DALLAS', 'DENVER', 'DETROIT', 'DOHA', 'DUBAI', 'DUBLIN', 'DUSSELDORF', 'FORT LAUDERDALE', 'FRANKFURT', 'FUKUOKA', 'GUANGZHOU', 'HANGZHOU', 'HELSINKI', 'HONG KONG', 'HOUSTON', 'ISTANBUL', 'JAKARTA', 'JEDDAH', 'JEJU', 'JOHANNESBURG', 'KUALA LUMPUR', 'KUNMING', 'LAS VEGAS', 'LISBON', 'LONDON', 'LOS ANGELES', 'MADRID', 'MANCHESTER', 'MANILA', 'MELBOURNE', 'MEXICO CITY', 'MIAMI', 'MILAN', 'MINNEAPOLIS', 'MOSCOW', 'MUMBAI', 'MUNICH', 'NEW DELHI', 'NEW YORK', 'NEWARK', 'ORLANDO', 'OSLO', 'PALMA DE MALLORCA', 'PARIS', 'PHILADELPHIA', 'PHOENIX', 'RIO DE JANEIRO', 'RIYADH', 'ROME', 'SALT LAKE CITY', 'SAN DIEGO', 'SAN FRANCISCO', 'SAO PAULO', 'SAPPORO', 'SEATTLE', 'SEOUL', 'SHANGHAI', 'SHENZHEN', 'SINGAPORE', 'STOCKHOLM', 'SYDNEY', 'TAIPEI', 'TAMPA', 'TOKYO', 'TORONTO', 'VANCOUVER', 'VIENNA', 'WASHINGTON', 'XIAMEN', 'ZURICH']
seat_letters = ['A', 'B', 'C', 'D', 'E', 'F']
seat_rows = [1, 71]

num_players = 8
num_people_per_player = 8

num_destinations = 3

num_image_categories = 4 # Hat, glasses, tshirt, hairstyle
num_image_options = 6 # No hat and 5 possible hats 


MAX_CHANGES_PER_CHALLENGE = num_players

branch_options = {
	'destination': [choice(destinations) for i in range(num_destinations)],
	'seat_row': list(range(1, 6)),
	'seat_letter': seat_letters,
	'luggage': list(range(3)),
	'player': list(range(num_players)),
	'reserved': [False]
}

for i in range(num_image_categories):
	branch_options['image_' + str(i)] = list(range(num_image_options))

challenge_queue = []
queue = {p: [] for p in range(num_players)}
people = {}

def add_node(data):
	person = generate_person(data)
	people[randrange(1e6, 1e7)] = person


def find_challenge(fixed, forbidden, variables, max_players, max_people_per_player):
	print('Find challenge')

	# Collect candidates that fit the fixed and forbidden parameters
	found = {}
	avoid = {}
	for p_id, person in people.items():
		for option, value in fixed.items():
			if person[option] != value:
				break
		else:
			# Check if reserved person
			if person['reserved']:
				avoid[p_id] = person
			else:
				# If found it might still be forbidden (also avoid)
				avoided = False
				if forbidden:
					for option, values in forbidden.items():
						if person[option] not in values:
							break
					else:
						avoid[p_id] = person
						avoided = True

				if not avoided:
					found[p_id] = person

	# Find all possible combinations of variables given the variables (MAX 3!)
	combinations = []
	for variable in variables:
		for opt in branch_options[variable]:
			if len(variables) == 1:
				combinations.append({variable: opt})
			else:
				for variable2 in variables[1:]:
					for opt2 in branch_options[variable2]:
						if len(variables) == 2:
							combinations.append({variable: opt, variable2: opt2})
						else:
							for opt3 in branch_options[variables[2]]:
								combinations.append({variable: opt, variable2: opt2, variables[2]: opt3})
	print(combinations)
	shuffle(combinations)


	# Test all possible combinations, key is if the challenge can be implemented and how much would need to be changed
	challenges = []

	for options in combinations:
		# Check if any of the avoids have this combination, 
		# and whether they can be removed
		to_remove = {}
		to_add = {}
		abort = False
		for p_id, person in avoid.items():
			for param, value in options.items():
				if person[param] != value:
					break
				elif person['reserved']:
					to_remove[p_id] = person
			else:
				abort = True
				break
		if abort:
			continue

		# Check if we have matching people with this combo
		matching = {}
		matching_per_player = {}
		for p_id, person in found.items():
			for param, value in options.items():
				if person[param] != value:
					break
			else:
				matching[p_id] = person
				if person['player'] in matching_per_player:
					matching_per_player[person['player']].append(p_id)
				else:
					matching_per_player[person['player']] = [p_id]

		# Add and remove people, to stay within the max number of players and people per player
		# Too many players = remove those with the least friction (= least people that match)
		friction = sorted(matching_per_player.items(), key=lambda x: len(x[1]), reverse=True)

		# Which players get removed, which people get removed
		remove_count = 0
		for i, (player_id, p_ids) in enumerate(friction):
			p_ids_remove = []

			# Remove a whole player (too many players)
			if i >= max_players:
				remove_count += len(p_ids)
				p_ids_remove = p_ids

			# Remove some people to stay within max people per player bound
			elif len(p_ids) > max_people_per_player:
				remove_count += len(p_ids) - max_people_per_player
				p_ids_remove = p_ids[max_people_per_player - 1:]

			# Have we already gone too far?
			if remove_count > MAX_CHANGES_PER_CHALLENGE:
				abort = True
				break

			# Just do it
			for p_id in p_ids_remove:
				to_remove[p_id] = matching[p_id]
				matching_per_player[player_id].remove(p_id)
				del matching[p_id]

		if abort:
			continue

		# Now we need to add players and people
		# If 1 player: force 1 player
		# If 2 players: force 2 players
		# If 3+ players: at least 3 players
		matching_per_player = {p: v for p, v in matching_per_player.items() if v}
		print(matching_per_player)



		# If noone fits the challenge: try to add people according to specs
		if not matching:
			# Which player is targeted? if not defined in fixed then we use a random (not forbidden player)
			player_id = fixed.get('player', None)
			if not player_id:
				forbidden_players = forbidden.get('player', [])
				if forbidden_players:
					player_id = choice([p for p in range(num_players) if p not in forbidden_players])
				else:
					player_id = choice(list(range(num_players)))

			# This is only possible if we can remove a person from this player
			remove_keys = to_remove.keys()
			for p_id, person in people.items():
				if person['player'] == player_id:
					if not person['reserved']:
						if not p_id in to_remove.keys():
							to_remove[p_id] = person
							break
			else:
				abort = True

			if abort:
				continue

			data = copy(fixed)
			data['player'] = player_id
			data['reserved'] = True

			data.update(options)
			# data[variable] = option
			ind = randrange(1e10, 1e11)
			to_add[ind] = generate_person(data)
			matching[ind] = copy(to_add[ind])
			print('No matches found: generated', player_id)

		# We will pick the option with the least to remove and add
		challenges.append([
			max(len(to_remove), len(to_add)), options, matching, to_remove, to_add
		])


	# for variable in variables:
	# 	options = copy(branch_options[variable])
	# 	shuffle(options)
	# 	for option in options:
	# 		# Check if any avoids, and whether they can be removed
	# 		to_remove = {}
	# 		to_add = {}
	# 		abort = False
	# 		for p_id, person in avoid.items():
	# 			if person[variable] == option:
	# 				if not person['reserved']:
	# 					to_remove[p_id] = person
	# 				else:
	# 					abort = True
	# 					break
	# 		if abort:
	# 			continue

	# 		# Find matching people			
	# 		matching = {}
	# 		matching_per_player = {}
	# 		for p_id, person in found.items():
	# 			if person[variable] == option:
	# 				matching[p_id] = person

	# 				if person['player'] in matching_per_player:
	# 					matching_per_player[person['player']].append(p_id)
	# 				else:
	# 					matching_per_player[person['player']] = [p_id]

	# 		# Now is a possibility to remove people, to stay within the max number of players and people per player
	# 		# Too many players = remove those with the least friction (= least people that match)
	# 		friction = sorted(matching_per_player.items(), key=lambda x: len(x[1]), reverse=True)
	# 		for i, (player_id, count) in enumerate(friction):
	# 			# Remove a whole player (too many players)
	# 			if i >= max_players:
	# 				for p_id in matching_per_player[player_id]:
	# 					to_remove[p_id] = matching[p_id]
	# 					del matching[p_id]

	# 			# Remove some people to stay within max people per player bound
	# 			elif count > max_people_per_player:
	# 				for p_id in matching_per_player[player_id][max_people_per_player - 1:]:
	# 					to_remove[p_id] = matching[p_id]
	# 					del matching[p_id]

	# 		if len(to_remove) > MAX_CHANGES_PER_CHALLENGE:
	# 			continue

	# 		# If noone fits the challenge, then we add one person to one player
	# 		if not matching:
	# 			# Which player is targeted? if not defined in fixed then we use a random (not forbidden player)
	# 			player_id = fixed.get('player', None)
	# 			if not player_id:
	# 				forbidden_players = forbidden.get('player', [])
	# 				if forbidden_players:
	# 					player_id = choice([p for p in range(num_players) if p not in forbidden_players])
	# 				else:
	# 					player_id = choice(list(range(num_players)))

	# 			# This is only possible if we can remove a person from this player

	# 			count = 0
	# 			for p_id, person in people.items():
	# 				if (not person['reserved']) and person['player'] == player_id and not p_id in to_remove.keys():
	# 					to_remove[p_id] = person
	# 					count += 1
	# 					if count >= max_people_per_player:
	# 						break

	# 			if count == 0:
	# 				continue

	# 			for i in range(count):
	# 				data = copy(fixed)
	# 				data['player'] = player_id
	# 				data['reserved'] = True
	# 				data[variable] = option
	# 				ind = randrange(1e6, 1e7)
	# 				to_add[ind] = generate_person(data)
	# 				matching[ind] = copy(to_add[ind])
	# 			print('No matches found: generated', count, player_id)

	# 		# We will pick the option with the least to remove and add
	# 		challenges.append([
	# 			len(to_remove), option, matching, to_remove, to_add
	# 		])

	if not challenges:
		return False

	challenge = sorted(challenges)[0]
	num_changes, options, matching, to_remove, to_add = challenge

	if num_changes > MAX_CHANGES_PER_CHALLENGE:
		return False

	summary = copy(fixed)
	summary.update(options)

	swaps = {p: [] for p in range(num_players)}

	all_challenges = [c[0] for c in copy(challenge_queue)] + [summary] 

	# Generate additional people that are in no challenge for all removed people
	balance = {i: 0 for i in range(num_players)}
	for p_id, person in to_remove.items():
		balance[person['player']] -= 1

	for p_id, person in to_add.items():
		balance[person['player']] += 1

	for player_id, bal in balance.items():
		if bal < 0:
			# Need to add people that do not clash with any other challenges
			for i in range(abs(bal)):
				data = {'player': player_id}
				person = generate_non_colliding_person(data, all_challenges)
				if not person:
					return False

				to_add[randrange(1e6, 1e7)] = person
		elif bal > 0:
			print('MORE ADDED THAN REMOVED')

		# Now match up the swaps
		p_out_queue = [p_id for p_id, person in to_remove.items() if person['player'] == player_id]
		p_in_queue = [p_id for p_id, person in to_add.items() if person['player'] == player_id]

		if len(p_out_queue) > len(p_in_queue):
			print('Too many to remove for player', player_id, len(p_out_queue), len(p_in_queue), p_in_queue, p_out_queue)
			print(summary)

		if len(p_out_queue) < len(p_in_queue):
			print('Too many to add for player', player_id, len(p_out_queue), len(p_in_queue), p_in_queue, p_out_queue)
			print(summary)

		# assert len(p_out_queue) == len(p_in_queue)

		c = 0
		for p_in, person in to_add.items():
			if person['player'] == player_id:
				p_out = p_out_queue.pop()
				swaps[player_id].append((p_out, p_in, person))
				people[p_out]['reserved'] = True
				c += 1

	solution = matching.keys()

	return [summary, solution, swaps]


def generate_non_colliding_person(data, challenges=None):
	# Try random generator
	for i in range(16):
		person = generate_person(data)
		if not collides_with_challenges(person, challenges):
			return person
	
	# Now try to change a challenge slightly
	if challenge_queue:
		for i in range(16):
			challenge = choice(copy(challenge_queue))[0]
			challenge['player'] = data['player']

			person = generate_person(challenge)

			# Change some attributes of the person (1 - 3)
			for j in range(randrange(1, 4)):
				opt = choice(branch_options.keys())
				person[opt] = rand_option(opt)

			if not collides_with_challenges(person, challenges):
				print('Found!!')
				return person

	# print("Could not generate non colliding person!")
	warnings[1] += 1
	return False


def collides_with_challenges(person, challenges=None):
	if challenges is None:
		challenges = [c[0] for c in challenge_queue]

	for challenge in challenges:
		same = all([person[opt] == val for opt, val in challenge.items() if opt != 'player'])
		if same:
			return True
	return False


def get_remove_candidates(player_id, num):
	'''
		Check if it is possible to remove num people from a player
	'''
	pass

def generate_person(data=None):
	person = {}

	if data is None:
		data = {}
	
	for option in branch_options.keys():
		if option.startswith('image_'):
			v = data.get(option, choice([0] * 3 + branch_options[option]))
		else:
			v = data.get(option, choice(branch_options[option]))
		person[option] = v

	return person


def implement_challenge(challenge, use_queue=True):
	summary, solution, swaps, c_type = challenge

	for player, player_swaps in swaps.items():
		if use_queue:
			queue[player] += player_swaps
		else:
			for swap in player_swaps:
				del people[swap[0]]
				people[swap[1]] = swap[2]

	for sol in solution:
		if sol in people:
			people[sol]['reserved'] = True

	challenge_queue.append(challenge)


c_types = []
warnings = [0, 0]

def step():
	'''
		First we get a third of the in_out queues done
		then we simulate one command done, 
		then we add a new command to the queue
	'''
	for player_id in range(num_players):
		if queue[player_id]:
			for i in range(int(ceil(len(queue[player_id]) * 1))):
				# Make the swap
				swap = queue[player_id].pop(0)
				people[swap[1]] = swap[2]
				try:
					del people[swap[0]]
				except:
					print('Could not remove person during swap', swap[0])

	# Simulate one command done
	player = randrange(num_players)
	if challenge_queue:
		challenge = challenge_queue.pop(0)

		c_types.append(challenge[-1])
		# print(challenge)
		missed = False

		for sol in challenge[1]:
			try:
				player_id = people[sol]['player']
				del people[sol]

				person = generate_non_colliding_person({'player': player_id})
				if person:
					people[randrange(1e6, 1e7)] = person

			except KeyError:
				# print('Could not fulfill challenge:', sol)
				missed = True
				continue

		if missed:
			warnings[0] += 1

		player = challenge[0]['player']


	# Create a new challenge
	for i in range(8):
		new_challenge = generate_player_challenge(player)
		if new_challenge:
			implement_challenge(new_challenge)
			break
	else:
		print('Could not find a follow up challenge')


def rand_option(param):
	return choice(branch_options[param])


def generate_player_challenge(player):
	c_type = choice([
		'boarding_row', 'boarding_last_call',
		'check_in', 'lost_and_found', 'info_seat',
		'police', 'vip', 'info_delayed'
		])

	forbidden = {}
	if random() > 0.25:
		forbidden['player'] = [player]

	if c_type == 'boarding_row':
		options = [{'destination': rand_option('destination')}, forbidden, ['seat_row'], 2, 2]

	elif c_type == 'boarding_last_call':
		options = [{}, forbidden, ['destination'], 12, 2]

	elif c_type == 'check_in':
		options = [{'destination': rand_option('destination')}, forbidden, ['luggage'], 2, 2]

	elif c_type == 'info_seat':
		options = [{'destination': rand_option('destination'), 'seat_letter': rand_option('seat_letter')}, forbidden, ['seat_row'], 1, 1]

	elif c_type == 'info_delayed':
		options = [{}, forbidden, ['destination'], 12, 2]

	elif c_type == 'lost_and_found':
		options = [{'destination': rand_option('destination'), 'luggage': randrange(1,3)}, forbidden, ['seat_row', 'seat_letter'], 1, 1]

	elif c_type == 'police':
		img = 'image_' + str(randrange(num_image_categories))
		options = [{}, forbidden, [img], 1, 1]

	elif c_type == 'vip':
		img = 'image_' + str(randrange(num_image_categories))
		options = [{}, forbidden, [img], 1, 1]

	challenge = find_challenge(*options)
	if challenge:
		challenge.append(c_type)
		challenge[0]['player'] = player
	return challenge


if __name__ == "__main__":
	for i in range(num_players):
		for p in range(num_people_per_player):
			add_node({'player': i})

	# Work ahead a bit, prepare some challenges for each player
	for j in range(1):
		for i in range(num_players):
			challenge = generate_player_challenge(i)
			if challenge:
				implement_challenge(challenge, use_queue=False)
			else:
				print('No Challenge found!')

	for j in range(10000):
		step()

	print('Number of people: {}, OK? {}'.format(len(people), len(people) == num_players * num_people_per_player))

	from collections import Counter

	c = Counter(c_types)
	print('Challenges: {}'.format(c))
	print('WARNINGS! Could not fulfill challenge: {}   Non-colliding not found: {}'.format(*warnings))

	# pprint(people)