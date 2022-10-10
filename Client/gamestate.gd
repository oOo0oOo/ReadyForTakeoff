extends Node

# Game port and ip
const ip = '127.0.0.1'

const DEFAULT_PORT = 44444

# Signal to let GUI know whats up
signal connection_failed()
signal connection_succeeded()
signal server_disconnected()

# Players dict stored as id:name
var current_room_id = ''
var ticket_unkown

onready var room_template = preload('res://Room.tscn')

func _ready():
# warning-ignore:return_value_discarded
	get_tree().connect("connected_to_server", self, "_connected_ok")
# warning-ignore:return_value_discarded
	get_tree().connect("connection_failed", self, "_connected_fail")
# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	# Try to connect right away
	connect_to_server()

func connect_to_server():
	var host = NetworkedMultiplayerENet.new()
	host.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(host)


# Callback from SceneTree, called when connect to server
func _connected_ok():
	emit_signal("connection_succeeded")

# Callback from SceneTree, called when server disconnect
func _server_disconnected():
	leave_room()
	connect_to_server()
	emit_signal("server_disconnected")

# Callback from SceneTree, called when unabled to connect to server
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")
	
	# Try to connect again
	connect_to_server()
	
func send_join_request(room_id):
	rpc_id(1, "join_room", room_id)
	
func send_leave_room_request():
	rpc_id(1, "leave_room", current_room_id)

func create_new_room(difficulty):
	rpc_id(1, "create_new_room", difficulty)

remote func join_room(room_id):
	# Load the room (the whole game)
	var main = get_node("/root/Main")
	main.get_node("ChooseScreen").hide()
	main.get_node("JoinScreen").hide()
	main.set_process(false)
	main.hide()
	
	var room = room_template.instance()
	room.name = room_id
	current_room_id = room_id
	get_tree().get_root().get_node('Server').add_child(room)
	
	# The room handles all further setup and communication with the server
	room.setup()

remote func leave_room():
	if current_room_id:
		get_node("/root/Server").get_node(current_room_id).queue_free()
		current_room_id = ''
	
	var main = get_node("/root/Main")
	main.set_process(true)
	main.show()

func get_current_room():
	return get_node("/root/Server").get_node(current_room_id)
