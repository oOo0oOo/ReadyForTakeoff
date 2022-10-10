extends Node

# Default game port
const DEFAULT_PORT = 44444

# Max number of players
const MAX_PLAYERS = 12

# Players dict stored as id: room_id
var players = {}

var room_hosts = {} # room_id: player_id (host)
var rooms = {} # room_id: room

onready var room_template = preload("res://Room.tscn")

func _ready():
	randomize()
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	
	# Create the server
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(host)

# Callback from SceneTree, called when client connects
func _player_connected(_id):
	print("Client ", _id, " connected")


# Callback from SceneTree, called when client disconnects
func _player_disconnected(id):
	remove_player(id)
	print("Client ", id, " disconnected")


# Room management
remote func create_new_room(difficulty):
	var caller_id = get_tree().get_rpc_sender_id()
	if room_hosts.values().has(caller_id):
		print('Client already started a room!')
	else:
		# Room id that does not collide
		var room_id = false
		while not room_id:
			room_id = utils.rand_airport_code()
			if get_tree().get_root().get_node("Server").has_node(room_id):
				room_id = false
		
		room_hosts[room_id] = caller_id
		
		# Create the new game room on the server
		var room = room_template.instance()
		room.name = room_id
		room.host_id = caller_id
		
		if difficulty == 1:
			room.current_round = 6
		elif difficulty == 2:
			room.current_round = 12
		
		get_tree().get_root().get_node("Server").add_child(room)
		
		rooms[room_id] = room
		players[caller_id] = room_id
		
		# Add the player to the room
		room.add_player(caller_id)
		
		rpc_id(caller_id, "join_room", room_id)
		
		print('Airport ', room_id, ' started by ', caller_id)


remote func join_room(room_id):
	var caller_id = get_tree().get_rpc_sender_id()
	
	room_id = room_id.to_upper()
	if rooms.has(room_id) and room_hosts[room_id] != caller_id:
		var success = rooms[room_id].add_player(caller_id)
		if success:
			players[caller_id] = room_id
			rpc_id(caller_id, "join_room", room_id)


remote func leave_room(room_id):
	var caller_id = get_tree().get_rpc_sender_id()
	remove_player(caller_id)


func remove_player(caller_id):
	if players.has(caller_id):
		var room_id = players[caller_id]
		
		# Remove all players
		if rooms.has(room_id):
			for player_id in players.keys():
				if players[player_id] == room_id:
					rooms[room_id].remove_player(caller_id)
					players.erase(player_id)
					rpc_id(player_id, "leave_room")
			rooms.erase(room_id)
	
			room_hosts.erase(room_id)
