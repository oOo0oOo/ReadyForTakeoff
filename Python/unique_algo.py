from random import choice, randrange, random, shuffle
from copy import copy
from pprint import pprint
from math import ceil


DESTINATIONS = ['AMSTERDAM', 'ANTALYA', 'ATHENS', 'ATLANTA', 'AUCKLAND', 'BALTIMORE', 'BANGKOK', 'BARCELONA', 'BEIJING', 'BERLIN', 'BOGOTA', 'BOSTON', 'BRASILIA', 'BRISBANE', 'BRUSSELS', 'CHARLOTTE', 'CHENGDU', 'CHICAGO', 'COPENHAGEN', 'DALLAS', 'DENVER', 'DETROIT', 'DOHA', 'DUBAI', 'DUBLIN', 'DUSSELDORF', 'FORT LAUDERDALE', 'FRANKFURT', 'FUKUOKA', 'GUANGZHOU', 'HANGZHOU', 'HELSINKI', 'HONG KONG', 'HOUSTON', 'ISTANBUL', 'JAKARTA', 'JEDDAH', 'JEJU', 'JOHANNESBURG', 'KUALA LUMPUR', 'KUNMING', 'LAS VEGAS', 'LISBON', 'LONDON', 'LOS ANGELES', 'MADRID', 'MANCHESTER', 'MANILA', 'MELBOURNE', 'MEXICO CITY', 'MIAMI', 'MILAN', 'MINNEAPOLIS', 'MOSCOW', 'MUMBAI', 'MUNICH', 'NEW DELHI', 'NEW YORK', 'NEWARK', 'ORLANDO', 'OSLO', 'PALMA DE MALLORCA', 'PARIS', 'PHILADELPHIA', 'PHOENIX', 'RIO DE JANEIRO', 'RIYADH', 'ROME', 'SALT LAKE CITY', 'SAN DIEGO', 'SAN FRANCISCO', 'SAO PAULO', 'SAPPORO', 'SEATTLE', 'SEOUL', 'SHANGHAI', 'SHENZHEN', 'SINGAPORE', 'STOCKHOLM', 'SYDNEY', 'TAIPEI', 'TAMPA', 'TOKYO', 'TORONTO', 'VANCOUVER', 'VIENNA', 'WASHINGTON', 'XIAMEN', 'ZURICH']
SEAT_LETTERS = ['window', 'aisle']


NUM_TRIES_CHALLENGE = 8


class Algo(object):

    def __init__(self, num_players=8, num_people_per_player=8,
            num_destinations=3, num_image_categories=3, num_image_options=10,
            add_challenges=True):

        self.num_players = num_players
        self.num_image_categories = num_image_categories

        self.branch_options = {
            'destination': [choice(DESTINATIONS) for i in range(num_destinations)],
            'seat_row': list(range(1, 6)),
            'seat_letter': SEAT_LETTERS,
            'luggage': list(range(3)),
            'player': list(range(num_players)),
            'reserved': [False],
            'gender': ['male', 'female']
        }

        for i in range(num_image_categories):
            self.branch_options['image_' + str(i)] = list(range(num_image_options))


        self.max_changes_per_challenge = int(ceil(num_players * 1.25))

        self.challenge_queue = []
        self.queue = {p: [] for p in range(num_players)}
        self.people = {}

        # DEBUG
        self.c_types = []
        self.warnings = [0, 0]

        # Add the initial people to the players
        for i in range(self.num_players):
            for p in range(num_people_per_player):
                person = self.generate_person({'player': i})
                self.people[randrange(1e10, 1e11)] = person

        # Work ahead a bit, prepare some challenges
        if add_challenges:
            count = 0
            while len(self.challenge_queue) < num_players:
                challenge = self.generate_challenge()
                if challenge:
                    self.implement_challenge(challenge, use_queue=False)

                count += 1
                if count >= 20:
                    print('Only {} / {} initial challenges found'.format(len(self.challenge_queue), num_players))


    def find_challenge(self, fixed, variables, max_players, max_people_per_player):
        # Collect candidates that fit the fixed parameters
        found = {}
        avoid = {}

        for p_id, person in self.people.items():
            for option, value in fixed.items():
                if person[option] != value:
                    break
            else:
                # Check if reserved person
                if person['reserved']:
                    avoid[p_id] = person
                else:
                    found[p_id] = person

        # Find all possible combinations of variables given the variables (MAX 3!)
        combinations = []
        for opt0 in self.branch_options[variables[0]]:
            if len(variables) == 1:
                combinations.append({variables[0]: opt0})
            else:
                for opt1 in self.branch_options[variables[1]]:
                    if len(variables) == 2:
                        combinations.append({variables[0]: opt0, variables[1]: opt1})
                    else:
                        for opt2 in self.branch_options[variables[2]]:
                            combinations.append({variables[0]: opt0, variables[1]: opt1, variables[2]: opt2})

        shuffle(combinations)

        # Test all possible combinations, key is if the challenge can be implemented and how much would need to be changed
        challenges = []

        for options in combinations:
            # Check if any of the avoids have this combination = bad
            to_remove = {}
            to_add = {}
            abort = False
            for p_id, person in avoid.items():
                for param, value in options.items():
                    if person[param] != value:
                        break
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
            change_count = 0
            for i, (player_id, p_ids) in enumerate(friction):
                p_ids_remove = []

                # Remove a whole player (too many players)
                if i >= max_players:
                    change_count += len(p_ids)
                    p_ids_remove = p_ids

                # Remove some people to stay within max people per player bound
                elif len(p_ids) > max_people_per_player:
                    change_count += len(p_ids) - max_people_per_player
                    p_ids_remove = p_ids[max_people_per_player - 1:]

                # Have we already gone too far?
                if change_count > self.max_changes_per_challenge:
                    abort = True
                    break

                # Just do it
                for p_id in p_ids_remove:
                    to_remove[p_id] = matching[p_id]
                    matching_per_player[player_id].remove(p_id)
                    del matching[p_id]

            if abort:
                continue

            # Now we need to add players according to max_players
            # If 1 player: force 1 player
            # If 2 players: force 2 players
            # If 3+ players: at least 3 players
            matching_per_player = {p: v for p, v in matching_per_player.items() if v}

            players_to_add = min(max_players, 3) - len(matching_per_player)
            if players_to_add > 0:
                players_to_add = min(players_to_add, self.num_players - len(matching_per_player))

                # Check remaining players if it is possible to remove a person = we can also add one
                players = [p for p in range(self.num_players) if p not in matching_per_player.keys()]
                shuffle(players)

                for player_id in players:
                    # Check if we can remove a person from this player
                    remove_id = False
                    blocked = to_remove.keys()
                    for p_id, person in self.people.items():
                        if person['player'] == player_id:
                            if not person['reserved']:
                                if not p_id in blocked:
                                    remove_id = p_id
                                    break

                    if not remove_id:
                        continue

                    # Do it
                    to_remove[remove_id] = self.people[remove_id]
                    matching_per_player[player_id] = []
                    players_to_add -= 1

                    if len(to_remove) > self.max_changes_per_challenge:
                        abort = True
                        break

                    # Found enough people
                    if players_to_add == 0:
                        break

                else:
                    # Not a valid solution because we could not find a suited player to add
                    abort = True

                if abort:
                    continue

                # Now finally we can add one new person if needed
                for player_id, p_ids in matching_per_player.items():
                    if not p_ids:
                        data = copy(fixed)
                        data.update(options)
                        data['player'] = player_id
                        data['reserved'] = True
                        ind = randrange(1e10, 1e11)

                        for i in range(8):
                            person = self.generate_person(data)
                            if not self.collides_with_challenges(person):
                                break
                        else:
                            continue

                        to_add[ind] = person
                        matching[ind] = copy(person)
                        matching_per_player[player_id] = [ind]

            # We will pick the option with the least to remove and add
            challenges.append([
                len(to_remove), copy(options), copy(matching), copy(to_remove), copy(to_add)
            ])

            # Immediately accept challenges with 0 changes
            if len(to_remove) == 0:
                break

        if not challenges:
            return False

        challenge = sorted(challenges)[0]
        num_changes, options, matching, to_remove, to_add = challenge

        if num_changes > self.max_changes_per_challenge:
            return False

        # Create the queues
        p_in_queue = {i: [] for i in range(self.num_players)}
        p_out_queue = {i: [] for i in range(self.num_players)}

        for p_id, person in to_remove.items():
            p_out_queue[person['player']].append(p_id)

        for p_id, person in to_add.items():
            p_in_queue[person['player']].append(p_id)

        # When more are removed than added we generate some random people
        # that do not collide with this and previous challenges.
        # This way we can always swap people and do not have to separately manage in and out queue

        summary = copy(fixed)
        summary.update(options)
        swaps = {p: [] for p in range(self.num_players)}
        all_challenges = [c[0] for c in copy(self.challenge_queue)] + [summary]

        for player_id in range(self.num_players):
            # Add new non colliding people if needed
            for i in range(len(p_out_queue[player_id]) - len(p_in_queue[player_id])):
                data = {'player': player_id}
                person = self.generate_non_colliding_person(data, all_challenges)
                if not person:
                    return False

                ind = randrange(1e10, 1e11)
                to_add[ind] = person
                p_in_queue[player_id].append(ind)

            # Now match up the swaps
            for p_in in p_in_queue[player_id]:
                p_out = p_out_queue[player_id].pop()
                swaps[player_id].append((p_out, p_in, to_add[p_in]))
                self.people[p_out]['reserved'] = True

        solution = matching.keys()

        return [summary, solution, swaps, {}]

    def generate_non_colliding_person(self, data, challenges=None):
        # Try random generator
        for i in range(20):
            person = self.generate_person(data)
            if not self.collides_with_challenges(person, challenges):
                return person

        # Now try to change a challenge slightly
        if self.challenge_queue:
            opt_allowed_change = copy(self.branch_options.keys())
            opt_allowed_change.remove('player')
            opt_allowed_change.remove('reserved')
            opt_allowed_change.remove('gender')

            p_data = copy(data)
            p_data.update(copy(self.challenge_queue[randrange(len(self.challenge_queue))][0]))

            for i in range(20):
                person = self.generate_person(copy(p_data))

                # Change some (1 - 3) attributes of the person
                # Not player or reserved!
                for j in range(randrange(1, 4)):
                    opt = choice(opt_allowed_change)
                    person[opt] = self.rand_option(opt)

                if not self.collides_with_challenges(person, challenges):
                    return person

        # print("Could not generate non colliding person!")
        self.warnings[1] += 1
        return False

    def collides_with_challenges(self, person, challenges=None):
        if challenges is None:
            challenges = [c[0] for c in self.challenge_queue]

        for challenge in challenges:
            same = all([person[opt] == val for opt, val in challenge.items() if opt not in ['player', 'reserved', 'gender']])
            if same:
                return True
        return False

    def generate_person(self, data=None):
        person = {}

        if data is None:
            data = {}

        for option in self.branch_options.keys():
            if option.startswith('image_'):
                v = data.get(option, choice([0] * 3 + self.branch_options[option]))
            else:
                v = data.get(option, choice(self.branch_options[option]))
            person[option] = v

        return person

    def implement_challenge(self, challenge, use_queue=True):
        '''
            This function takes a proposed challenge and sets up everything for it to be used.
            However, normally queues are used and nothing is swapped
        '''
        summary, solution, swaps, meta = challenge

        for player, player_swaps in swaps.items():
            if use_queue:
                self.queue[player] += player_swaps
            else:
                for swap in player_swaps:
                    del self.people[swap[0]]
                    self.people[swap[1]] = swap[2]

        for sol in solution:
            if sol in self.people:
                self.people[sol]['reserved'] = True

        challenge[3]['player'] = -1
        challenge[3]['found'] = []

        self.challenge_queue.append(challenge)

    def new_challenge_for_player(self, player_id):
        '''
            Get the next free challenge from the queue and assign to player.
            Also make sure the challenge is possible.
        '''

        for ch in self.challenge_queue:
            if ch[3]['player'] == player_id:
                return False

        # First we get some of the swaps in the queue done (for each player)
        RATIO = 0.3
        for p_id in range(self.num_players):
            if self.queue[p_id]:
                for i in range(int(ceil(len(self.queue[p_id]) * RATIO))):

                    # Make the swap
                    swap = self.queue[p_id].pop(0)
                    self.people[swap[1]] = swap[2]

                    # GODOT: Swap people
                    try:
                        del self.people[swap[0]]
                    except:
                        print('Could not remove person during swap', swap[0])

        # Next possible challenge
        found = False
        for i, ch in enumerate(self.challenge_queue):
            if ch[3]['player'] == -1:
                for sol in ch[1]:
                    if sol not in self.people.keys():
                        print('Too early for challenge!', i)
                        break
                else:
                    ch[3]['player'] = player_id
                    found = ch
                    break

        if found:
            # Need to generate a new challenge
            ch = self.generate_challenge()
            if ch:
                self.implement_challenge(ch)

        return found

    def person_selected(self, p_id, c_cat):
        # Check if correct person
        challenge = False
        for challenge_id, ch in enumerate(self.challenge_queue):
            if ch[3]['player'] != -1:
                if p_id in ch[1]:
                    if c_cat == 'info' and ch[3]['type'] in ['info_seat', 'info_delayed', 'info_parent', 'info_first']:
                        challenge = ch
                    elif c_cat == 'boarding' and ch[3]['type'] in ['boarding_row', 'boarding_last_call', 'boarding_window', 'boarding_first']:
                        challenge = ch
                    elif c_cat == 'check_in' and ch[3]['type'] in ['check_in', 'check_in_row', 'check_in_first']:
                        challenge = ch
                    elif c_cat == 'lost_and_found' and ch[3]['type'] in ['lost_and_found', 'lost_and_found_only_seat']:
                        challenge = ch
                    elif c_cat == 'police' and ch[3]['type'] in ['police', 'police_row', 'police_destination']:
                        challenge = ch
                    elif c_cat == 'vip' and ch[3]['type'] in ['vip', 'vip_multi']:
                        challenge = ch
                    break

        if challenge:
            challenge[3]['found'].append(p_id)

            # Remove the person from the player
            player_id = self.people[p_id]['player']
            del self.people[p_id]
            self.people[randrange(1e10, 1e11)] = self.generate_non_colliding_person({'player': player_id})

            if sorted(challenge[3]['found']) == sorted(challenge[1]):
                self.challenge_queue.pop(challenge_id)
                return {'completed': challenge[3]['player']}

            return {'completed': -1}

        else:
            # print('MISTAKE!!')
            return False

    def rand_option(self, param):
        return choice(self.branch_options[param])

    def get_challenge_options(self, c_type):
        ##
        ## Boarding
        ##
        if c_type == 'boarding_row':
            options = [
                {'destination': self.rand_option('destination')},
                ['seat_row'], 2, 2]

        elif c_type == 'boarding_last_call':
            options = [{}, ['destination'], 8, 2]

        # Boarding window, aisle
        elif c_type == 'boarding_window':
            options = [{}, ['destination', 'seat_letter'], 2, 2]

        # Preferrential boarding
        elif c_type == 'boarding_first':
            options = [{'seat_row': randrange(1, 3)}, ['destination'], 2, 2]

        ##
        ## Check in
        ##
        elif c_type == 'check_in':
            options = [{}, ['destination', 'luggage'], 8, 2]

        elif c_type == 'check_in_row':
            options = [{}, ['destination', 'luggage', 'seat_row'], 2, 2]

        # First class check in, business class check in
        elif c_type == 'check_in_first':
            options = [{'seat_row': randrange(1, 3)}, ['destination', 'luggage'], 2, 2]

        # All oversized: luggage == 3

        ##
        ## Info
        ##
        elif c_type == 'info_seat':
            options = [{'destination': self.rand_option('destination'), 'seat_letter': self.rand_option('seat_letter')}, ['seat_row'], 1, 1]

        elif c_type == 'info_delayed':
            options = [{}, ['destination'], 8, 2]

        # Missing parent! destination, image
        elif c_type == 'info_parent':
            img = 'image_' + str(randrange(self.num_image_categories))
            options = [{}, ['destination', img], 1, 1]

        # First Class Lounge: seat row = 1
        # Business class Buffet: seat row 2 or 3
        elif c_type == 'info_first':
            options = [{'seat_row': randrange(1, 3)}, ['destination'], 2, 2]


        ##
        ## Lost and found
        ##
        elif c_type == 'lost_and_found_only_seat':
            options = [{'luggage': randrange(1, 3)}, ['seat_row', 'seat_letter'], 1, 1]

        elif c_type == 'lost_and_found':
            options = [{'luggage': randrange(1, 3)}, ['seat_row', 'seat_letter', 'destination'], 1, 1]

        ##
        ## Police
        ##
        elif c_type == 'police':
            img = 'image_' + str(randrange(self.num_image_categories))
            options = [{}, [img], 1, 1]

        # image & seat_row
        elif c_type == 'police_row':
            img = 'image_' + str(randrange(self.num_image_categories))
            options = [{}, [img, 'seat_row'], 1, 1]

        elif c_type == 'police_destination':
            img = 'image_' + str(randrange(self.num_image_categories))
            options = [{}, [img, 'destination'], 1, 1]

        ##
        ## VIP
        ##
        elif c_type == 'vip':
            img = 'image_' + str(randrange(self.num_image_categories))
            options = [{}, [img], 1, 1]

        # Img & destination
        elif c_type == 'vip_multi':
            img = 'image_' + str(randrange(self.num_image_categories))
            options = [{}, [img], 2, 2]

        return options

    def generate_challenge(self, challenge_type=None):
        if challenge_type is None:
            c_type = choice([
                'boarding_row', 'boarding_last_call',
                'boarding_window', 'boarding_first',
                'check_in', 'check_in_row', 'check_in_first',
                'info_seat', 'info_delayed', 'info_parent', 'info_first',
                'lost_and_found', 'lost_and_found_only_seat',
                'police', 'police_row', 'police_destination',
                'vip', 'vip_multi'
            ])
        else:
            c_type = challenge_type

        for i in range(NUM_TRIES_CHALLENGE):
            options = self.get_challenge_options(c_type)
            challenge = self.find_challenge(*options)
            if challenge:
                challenge[3]['type'] = c_type
                return challenge

        # Cannot generate this challenge at the moment..
        # Try a filler (all except boarding and check in)
        for i in range(3):
            c_type = choice(['info_seat', 'info_delayed', 'info_parent', 'info_first',
                'lost_and_found', 'lost_and_found_only_seat',
                'police', 'police_row', 'police_destination',
                'vip', 'vip_multi'])

            options = self.get_challenge_options(c_type)
            challenge = self.find_challenge(*options)
            if challenge:
                challenge[3]['type'] = c_type
                return challenge

        return False


if __name__ == "__main__":

    algo = Algo(num_players=8)

    for j in range(100):
        algo.step()

    print('Number of people: {}, OK? {}'.format(len(algo.people), len(algo.people) == algo.num_players * 8))

    from collections import Counter

    c = Counter(algo.c_types)
    print('Challenges: {}'.format(c))
    print('WARNINGS! Could not fulfill challenge: {}   Non-colliding not found: {}'.format(*algo.warnings))

    # pprint(people)
