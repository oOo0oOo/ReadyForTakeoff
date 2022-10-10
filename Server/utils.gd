extends Node

var cur_id = 10000000
const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']

# Some random functions
func choice(arr):
	arr = arr.duplicate(true)
	return arr[randi() % arr.size()]


func randrange(start, end):
	return start + randi() % (end - start)


func sample(arr, num):
	arr = arr.duplicate(true)
	var sample = []
	for i in range(num):
		var x = randi() % arr.size()
		sample.append(arr[x])
		arr.remove(x)
	return sample
	

func rand_id():
	cur_id += 1
	return cur_id

func rand_airport_code():
	var code = choice(letters)
	for i in range(2):
		code += choice(letters)
	return code
