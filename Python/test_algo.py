import unittest
from random import sample, randrange, shuffle, choice
from copy import copy
from pprint import pprint
from collections import Counter

from unique_algo import Algo


class TestAlgoSimple(unittest.TestCase):

    def challenge_possible(self, challenge, algo):
        options, solution, swaps, meta = challenge
        people = algo.people

        # Check swaps
        to_remove = []
        for player_id, p_swaps in swaps.items():
            for p_out, p_in, person in p_swaps:
                self.assertEqual(player_id, person['player'], 'Incorrect swap in challenge: player in')
                self.assertEqual(player_id, people[p_out]['player'], 'Incorrect swap in challenge: player out')
                to_remove.append(p_out)
                if p_in in solution:
                    self.assertTrue(person['reserved'], 'Incorrect swap in challenge: player not reserved')
                    solution.remove(p_in)

        # Check all people if they match
        for p_id, person in people.items():
            matched = False
            for attr, option in options.items():
                if person[attr] != option:
                    break
            else:
                # Found a person that matches
                if p_id in solution:
                    solution.remove(p_id)
                elif p_id in to_remove:
                    pass
                else:
                    raise RuntimeError('Person should be removed or in solution!')
                matched = True

            if not matched:
                if p_id in solution:
                    raise RuntimeError('Person should be in the solution!')

        self.assertEqual(len(solution), 0)

    def implementation_correct(self, ch, algo):
        for player_id, swaps in ch[2].items():
            for swap in swaps:
                # Find in queue
                for t_swap in algo.queue[player_id]:
                    if t_swap[0] == swap[0]:
                        break
                else:
                    raise RuntimeError("Incorrect swap implementation")

                self.assertTrue(algo.people[swap[0]]['reserved'])

        # Also check if all solution people are reserved
        for p_id in ch[1]:
            if p_id in algo.people:
                self.assertTrue(algo.people[p_id]['reserved'])

    def challenge_ready(self, ch, algo):
        '''
            Check if all the people are out on the playing field and the challenge is possible.
        '''
        for p_id in ch[1]:
            self.assertTrue(p_id in algo.people.keys(), 'Challenge not ready: person not swapped in yet.')

        for p_id, person in algo.people.items():
            for attr, option in ch[0].items():
                if person[attr] != option:
                    # Found a not matching person
                    self.assertFalse(p_id in ch[1], 'Challenge wrong! Person should not be in solution! {}'.format(p_id))
                    break
            else:
                # Found a person
                self.assertTrue(p_id in ch[1], 'Challenge wrong! Person should be in solution! {}'.format(p_id))

    def test_setup(self):
        for num_players in range(2, 9):
            for num_people_per_player in range(6, 11):
                algo = Algo(num_players = num_players,
                    num_people_per_player = num_people_per_player,
                    add_challenges = False)

                # Check if people are correct
                self.assertEqual(algo.num_players, num_players)
                self.assertEqual(len(algo.people), num_people_per_player * num_players)

                self.assertTrue(all([type(i) == int for i in algo.people.keys()]))
                self.assertTrue(all([type(i) == dict for i in algo.people.values()]))

        params = ['image_' + str(i) for i in range(algo.num_image_categories)]
        params = sorted(params + ['destination', 'seat_row', 'seat_letter', 'luggage', 'player', 'reserved', 'gender'])

        for p_id, person in algo.people.items():
            self.assertEqual(sorted(person.keys()), params)
            self.assertFalse(person['reserved'])

    def test_single_variable_challenge(self):
        algo = Algo()
        params = ['image_' + str(i) for i in range(algo.num_image_categories)]
        params = sorted(params + ['destination', 'seat_row', 'seat_letter', 'luggage'])

        fails = {v: 0 for v in params}
        for variable in params:
            for num_players in range(2, 9):
                for max_players in range(1, num_players + 1):
                    for max_people_per_player in range(1, 9):
                        algo = Algo(num_players = num_players, add_challenges = False)
                        options = [{}, [variable], max_players, max_people_per_player] # Fixed, forbidden, variables, max_players, max_people_per_player
                        challenge = algo.find_challenge(*options)
                        if not challenge:
                            # fails.append(options)
                            if variable in fails:
                                fails[variable] = max(fails[variable], max_people_per_player)
                            else:
                                fails[variable] = max_people_per_player
                        else:
                            # Check if the challenges is possible
                            self.challenge_possible(challenge, algo)
                            self.assertEqual(challenge[0].keys(), [variable])

        fails = {k: v for k, v in fails.items() if v > 0}
        print('Single variable fails for max_people_per_player <=')
        print(fails)

    def test_fuzzy_challenge(self):
        num = 1000
        fails = []

        algo = Algo()
        params = ['image_' + str(i) for i in range(algo.num_image_categories)]
        params = sorted(params + ['destination', 'seat_row', 'seat_letter', 'luggage'])

        print('Testing {} fuzzy challenges'.format(num))
        for i in range(num):
            if i and not i % 5000:
                print('{} done'.format(i))
            num_players = randrange(2, 9)
            max_players = randrange(1, num_players + 1)
            max_people_per_player = randrange(1, 9)

            algo = Algo(num_players=num_players, add_challenges=False)

            num_var = randrange(1, 3)
            num_fixed = randrange(0, 3)

            par = copy(params)
            shuffle(par)

            # We know that a single variable just doesnt work for destination and luggage
            if num_fixed == 0:
                while par[0] in ['destination', 'luggage', 'seat_letter']:
                    shuffle(par)

            variables = par[:num_var]
            fixed_params = par[num_var:num_var + num_fixed]
            fixed = {p: choice(algo.branch_options[p]) for p in fixed_params}

            ch = algo.find_challenge(fixed, variables, max_players, max_people_per_player)

            if ch:
                self.challenge_possible(ch, algo)
                algo.implement_challenge(ch)
                self.implementation_correct(ch, algo)

            else:
                fails.append((num_players, tuple(variables), tuple(fixed_params), max_players, max_people_per_player))

            if algo.warnings[1] > 0:
                print('Challenge had problems finding {} non colliding people'.format(algo.warnings[1]))

        all_fails = sorted(list(set(fails)))
        # The following challenges failed to generate
        fmt = '\n'.join(['Num players: {} Variables: {}, fixed: {}, max_players: {}, max_peopler_per_player: {}'.format(*f) for f in fails])

        print('The following challenges could not be generated:\n' + fmt)


    def test_generate_challenge(self):
        c_types = ['boarding_row', 'boarding_last_call',
            'boarding_window', 'boarding_first',
            'check_in', 'check_in_row', 'check_in_first',
            'info_seat', 'info_delayed', 'info_parent', 'info_first',
            'lost_and_found', 'lost_and_found_only_seat',
            'police', 'police_row', 'police_destination',
            'vip', 'vip_multi']

        print('Testing the preset types of challenges:')
        for c_type in c_types:
            for num_players in range(2, 9):
                for i in range(25):
                    algo = Algo(num_players = num_players, add_challenges=False)

                    # Generate one for each player
                    for i in range(num_players + 1):
                        ch = algo.generate_challenge(c_type)

                        if algo.warnings[1] > 0:
                            print('Challenge {} ({} players): {} non colliding people missing'.format(c_type, num_players, algo.warnings[1]))

                        if ch:
                            try:
                                self.challenge_possible(ch, algo)
                            except Exception as err:
                                print(c_type, 'failed hard:', err)
                                raise

                            algo.implement_challenge(ch)
                            self.implementation_correct(ch, algo)

    def test_generate_challenge_setup(self):
        for num_players in range(2, 9):
            for i in range(50):
                algo = Algo(num_players=num_players, add_challenges=True)

                self.assertTrue(num_players >= len(algo.challenge_queue) >= 2)

                if algo.warnings[1] > 0:
                    print('Initial challenge ({} players): {} non colliding people missing'.format(num_players, algo.warnings[1]))

                for i, ch in enumerate(algo.challenge_queue):
                    try:
                        self.challenge_ready(ch, algo)
                    except Exception as err:
                        print('Challenge not ready!', i, err)
                        raise

                for i in range(2):
                    ch = algo.generate_challenge()

                    if algo.warnings[1] > 0:
                        print('Additional challenge ({} players): {} non colliding people missing'.format(num_players, algo.warnings[1]))

                    if ch:
                        self.challenge_possible(ch, algo)
                        algo.implement_challenge(ch)
                        self.implementation_correct(ch, algo)

    def test_new_challenge_for_player(self):
        for num_players in range(2, 9):
            for i in range(30):
                algo = Algo(num_players=num_players, add_challenges=True)

                players = list(range(num_players))
                shuffle(players)
                for player_id in players[:2]:
                    ch = algo.new_challenge_for_player(player_id)
                    self.assertEqual(ch[3]['player'], player_id)
                    self.assertEqual(ch[3]['found'], [])
                    self.assertEqual(type(ch[3]['type']), str)

    def test_person_selected(self):
        for num_players in range(2, 9):
            for i in range(1):
                algo = Algo(num_players=num_players, add_challenges=True)

                challenges = []
                for round_id in range(10):
                    for player_id in range(num_players):
                        ch = algo.new_challenge_for_player(player_id)
                        if ch:
                            challenges.append(ch)

                        if len(challenges) > 3:
                            # Fulfill challenge
                            ch = challenges.pop(0)

                            c_type = ch[3]['type']
                            for c in ['info', 'boarding', 'check_in', 'lost_and_found', 'police', 'vip']:
                                if c_type.startswith(c):
                                    cat = c
                                    break

                            for i, p_id in enumerate(ch[1]):
                                # Wrong cat
                                wrong = copy(['info', 'boarding', 'check_in', 'lost_and_found', 'police', 'vip'])
                                wrong.remove(cat)
                                wrong = choice(wrong)
                                self.assertEqual(algo.person_selected(p_id, wrong), False)

                                # Wrong id
                                for p in range(5):
                                    self.assertEqual(algo.person_selected(randrange(1e10, 1e11), cat), False)

                                # Right
                                ret = algo.person_selected(p_id, cat)

                                # Last one should give finished player
                                if i == len(ch[1]) - 1:
                                    self.assertEqual(ret, {'completed': ch[3]['player']})
                                else:
                                    self.assertEqual(ret, {'completed': -1})


if __name__ == '__main__':
    unittest.main()
