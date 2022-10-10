extends Node

var images = {}
var unknown = {}
var airplanes = []

func _ready():
	for gender in ['male', 'female']:
		images[gender] = {
			'brows': [],
#			'ears': [],
			'eyes': [],
			'glasses': [],
			'hair': [],
			'mouth': [],
			'nose': [],
			'outline': [],
			'shirt': []
		}
		var base = get_node(gender)
		for type in images[gender].keys():
			for option in base.get_node(type).get_children():
				images[gender][type].append(option.texture)
	
	unknown = {'female': $female_unknown.texture, 'male': $male_unknown.texture}
	
	for ap in $airplanes.get_children():
		airplanes.append(ap.texture)
