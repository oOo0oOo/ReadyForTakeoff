extends Node

# Influences of the config (for a round)

# 1. Host selected difficulty
# 2. Which round the game is in
# 3. Phase: Normal or last call
# 4. Number of players

# Variables of the config
# - Challenge types
# - Is challenge timed?
# - Challenge time
# - How many challenges in parallel?
const MAX_PLAYERS = 8

# Depending on the number of players, number of active challenges at any time
var challenge_simultaneous = {
	1:1, 2: 2, 3: 2, 4: 3, 5: 3, 6: 4, 7: 4, 8: 4
}

const all_challenges = [
			'boarding_last_call',
			'info_delayed', 
			
			'boarding_row', 
			'boarding_first',
			'boarding_window', 
			'check_in', 
			
			'check_in_row', 
			'check_in_first',

			'info_seat', 
			'info_first',
			'info_parent', 
			
			'lost_and_found_only_seat',
			'lost_and_found', 
			
			'police', 
			'police_destination',
			'police_row', 
			
			'vip', 
			'vip_multi'
]

const NUM_ROUNDS_PER_PHASE = 2

# Setup a few difficulty levels
# {'challenge_types': [], 'challenge_timed': {probability of a timed challenge}}
var airport_phase = [
	# Very easy (only very few challenges)
	{
		'challenge_types': ['boarding_row', 'check_in', 'police', 'vip'],
		'challenge_timed': {},
		'name': 'Tiny Airfield',
		'challenge_time': 30,
		'normal_challenges': 4,
		'last_call_challenges': 2
	},
	
	# Easy
	{
		'challenge_types': ['boarding_row', 'check_in', 'vip_multi', 'police', 'vip'],
		'challenge_timed': {'boarding_row': 0.3, 'vip': 0.2},
		'name': 'Bush Airport',
		'challenge_time': 30,
		'normal_challenges': 6,
		'last_call_challenges': 3
	},
	
	# + INFO
	{
		'challenge_types': ['boarding_row', 'check_in', 'vip_multi', 'police', 'vip', 'info_seat', 'police_two'],
		'challenge_timed': {'boarding_row': 0.3, 'vip': 0.2, 'check_in': 0.2},
		'name': 'Basic Airport',
		'challenge_time': 30,
		'normal_challenges': 8,
		'last_call_challenges': 4
	},
	
	# + LOST AND FOUND
	{
		'challenge_types': ['boarding_row', 'check_in', 'vip_multi', 'police', 'vip', 'info_seat', 'lost_and_found_only_seat', 'police_two', 'vip_two'],
		'challenge_timed': {'boarding_row': 0.3, 'vip': 0.2, 'info_seat': 0.2, 'check_in': 0.2},
		'name': 'Rural Airport',
		'challenge_time': 25,
		'normal_challenges': 10,
		'last_call_challenges': 5
	},
	
	# NORMAL
	{
		'challenge_types': ['boarding_row', 'check_in', 'vip_multi', 'police', 'police_destination', 'vip', 'info_seat', 
		'lost_and_found_only_seat', 'info_seat_complete', 'police_two', 'vip_two'],
		'challenge_timed': {'boarding_row': 0.4, 'vip': 0.3, 'info_seat': 0.3,  'police': 0.5, 'check_in': 0.3},
		'name': 'Local Airport',
		'challenge_time': 25,
		'normal_challenges': 12,
		'last_call_challenges': 5
	},
	
	{
		'challenge_types': ['boarding_row', 'check_in', 'check_in_row', 'vip_multi', 'police', 'police_destination', 'vip', 'info_seat', 
		'lost_and_found_only_seat', 'info_parent', 'info_seat_complete', 'police_two', 'vip_two'],
		'challenge_timed': {'boarding_row': 0.4, 'vip': 0.3, 'info_seat': 0.3, 'police': 0.5, 'info_parent': 1.0, 'check_in': 0.3},
		'name': 'Regional Airport',
		'challenge_time': 25,
		'normal_challenges': 15,
		'last_call_challenges': 5
	},
	
	{
		'challenge_types': ['boarding_row', 'check_in', 'check_in_row', 'vip_multi', 'police', 'police_destination', 
			'vip', 'info_seat', 'lost_and_found_only_seat', 'info_parent', 'police_row', 'info_seat_complete', 'police_two', 'vip_two', 'vip_three'],
		'challenge_timed': {'boarding_row': 0.4, 'vip': 0.3, 'info_seat': 0.3, 'police': 0.9, 'info_parent': 1.0, 'police_destination': 0.5, 'police_row': 0.5, 'check_in': 0.3},
		'name': 'National Airport',
		'challenge_time': 25,
		'normal_challenges': 15,
		'last_call_challenges': 5
	},
	
	{
		'challenge_types': ['boarding_row', 'check_in', 'check_in_row', 'vip_multi', 'police', 'police_destination', 
			'vip', 'info_seat', 'lost_and_found_only_seat', 'info_parent', 'police_row', 'lost_and_found', 'info_seat_complete', 'police_two', 'vip_two', 'vip_three', 'police_three'],
		'challenge_timed': {'boarding_row': 0.4, 'vip': 0.4, 'info_seat': 0.3, 'police': 0.9, 'info_parent': 1.0, 'police_destination': 0.5, 'police_row': 0.5, 'check_in': 0.3},
		'name': 'International Airport',
		'challenge_time': 22,
		'normal_challenges': 15,
		'last_call_challenges': 5
	},
	
	# All challenges
	{
		'challenge_types': ['boarding_row', 'check_in', 'check_in_row', 'vip_multi', 'police', 'police_destination', 
			'vip', 'info_seat', 'lost_and_found_only_seat', 'info_parent', 'police_row', 'lost_and_found', 'boarding_window', 
			'info_seat_complete', 'police_two', 'vip_two', 'vip_three', 'police_three'],
		'challenge_timed': {'boarding_row': 0.4, 'vip': 0.4, 'info_seat': 0.3, 'police': 0.9, 'info_parent': 1.0, 'police_destination': 0.5, 'police_row': 0.5, 'check_in': 0.3},
		'name': 'Large Airport Hub',
		'challenge_time': 22,
		'normal_challenges': 15,
		'last_call_challenges': 5
	},
	
	# Just a bit stressier from now..
	{
		'challenge_types': ['boarding_row', 'check_in', 'check_in_row', 'vip_multi', 'police', 'police_destination', 
			'vip', 'info_seat', 'lost_and_found_only_seat', 'info_parent', 'police_row', 'lost_and_found', 'boarding_window', 
			'info_seat_complete', 'police_two', 'vip_two', 'vip_three', 'police_three'],
		'challenge_timed': {'boarding_row': 0.6, 'vip': 0.6, 'info_seat': 0.6, 'police': 0.9, 'info_parent': 1.0, 'police_destination': 0.6, 'police_row': 0.6, 'vip_multi': 0.9, 'check_in': 0.6,
		'lost_and_found': 0.5, 'vip_two': 0.5, 'vip_three': 0.5, 'police_two': 0.5, 'police_three': 0.5, 'boarding_window': 0.3},
		'name': 'Space Port',
		'challenge_time': 20,
		'normal_challenges': 15,
		'last_call_challenges': 5
	},
]


# In the last call phase we have only a limited set of challenges (we add these challenges)
var last_call = {
	'challenge_types': ['boarding_row', 'boarding_row', 'boarding_row'],
	'challenge_timed': {'boarding_row': 1.0, 'vip': 0.5, 'info_seat': 0.5, 'police': 0.5, 'info_parent': 0.5, 'police_destination': 0.5, 'police_row': 0.5, 'vip_multi': 0.5}
}
