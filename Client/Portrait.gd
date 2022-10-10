extends Node2D

var images
var types
var unknown

func _ready():
	randomize()
	# Choose a random rotation
	var bounds = [-9, 9]
	
	rotation_degrees = bounds[0] + randi() % (bounds[1] - bounds[0])
	
	images = PortraitImages.images
	types = images['male'].keys()
	unknown = PortraitImages.unknown

func setup(data, mr_x = false):
	var portrait_data = {}
	
	var gender = data['gender']
	
	for type in types:
		var img_id
		
		if type in data.keys():
			img_id = data[type]
			get_node(type).show()
		elif mr_x:
			img_id = 0
			get_node(type).hide()
		else:
			img_id = randi() % images[gender][type].size()
			get_node(type).show()
		
		portrait_data[type] = img_id
		get_node(type).texture = images[gender][type][img_id]
	
	if mr_x:
		get_node('outline').show()
		get_node('outline').texture = unknown[gender]
	
	return portrait_data
