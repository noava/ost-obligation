extends Node

const PORT = 13154

var peer: SteamMultiplayerPeer
var _handlers: Array[SessionHandler] = []

func _ready() -> void:
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_host_disconnected)

####################################################################
####################### HANDLER SUBSCRIPTION #######################
####################################################################
func register_handler(_handler):
	if _handler is SessionHandler and not _handlers.has(_handler):
		_handlers.append(_handler)

func unregister_handler(_handler):
	if _handler is SessionHandler and _handlers.has(_handler):
		_handlers.erase(_handler)

func notify_handlers(_method: StringName, ...args: Array):
	for handler in _handlers:
		handler.callv(_method, args)


#####################
###### HELPERS ######
#####################
# These gets called by SteamManager when players do stuff
# these initiate the p2p connections and stuff

# gets called when a lobby is created
func create_socket():
	peer = SteamMultiplayerPeer.new()
	peer.create_host(0)
	multiplayer.set_multiplayer_peer(peer)
	# add the host itself to the peer list
	State.lobby_data.peer_members[1] = State.user_data.steam_id
	print("establishing connection (host)")

# gets called when a player joins a lobby
func connect_socket(_id: int):
	peer = SteamMultiplayerPeer.new()
	peer.create_client(_id, 0)
	multiplayer.set_multiplayer_peer(peer)
	print("establishing connection (client)")

# gets called by the host when the game is starting
func start_game(_scene: PackedScene):
	if not multiplayer.is_server():
		return
	load_game_scene.rpc(_scene.resource_path)
	notify_handlers("on_game_start", State.lobby_data.peer_members.keys())


#######################
###### CALLBACKS ######
#######################
# this gets only called on clients when they disconnect from host
# this needs fixing
func _host_disconnected():
	if !State.menu_scene or !State.game_scene: 
		print("set the scenes in the State correctly")
		return

	print("disconnected from host")
	multiplayer.set_multiplayer_peer(null)

	# remove game scene if it exists
	for child in get_tree().get_root().get_children():
		if child.scene_file_path == State.game_scene.resource_path:
			child.queue_free()
			break

	# add menu if not present
	var menu_exists = false
	for child in get_tree().get_root().get_children():
		if child.scene_file_path == State.menu_scene.resource_path:
			menu_exists = true
			break

	if not menu_exists:
		var menu_instance = State.menu_scene.instantiate()
		get_tree().get_root().add_child(menu_instance)

	State.current_state = State.GameState.LOBBY

func _connected_ok():
	print("connected_ok")

func _connected_fail():
	print("connected_fail")
	multiplayer.set_multiplayer_peer(null)
	State.current_state = State.GameState.LOBBY

func _player_disconnected(_id):
	State.lobby_data.peer_members.erase(_id)
	print("player with peer id: " + str(_id) + " left....")

	if multiplayer.is_server():
		notify_handlers("on_player_leave", _id)

func _player_connected(_id):
	print("player_connected")

	var my_steam_id = Steam.getSteamID()
	register_peer.rpc_id(_id, my_steam_id)

	# idk if i like using steam in this file at all but idk for now
	# but this will let late comming players load the game scene too...
	# apperently trying to load that scene after this funciton doestn work since
	# godot looks for the multiplayerspawner automatically after this callback,
	# and if thats not loaded it just throws an error
	var _lobby_id = State.lobby_data.id
	var _started = Steam.getLobbyData(_lobby_id, "started")
	if _started == "1" and !multiplayer.is_server():
		load_game_scene(State.game_scene.resource_path)

	if multiplayer.is_server():
		notify_handlers("on_player_join", _id)


###################
###### RPC's ######
###################
# gets called locally on all clients, and makes sure each client has 
# loaded the game scene and the multiplayerspawner so that everything 
# is synced when the host spawns the players
@rpc("call_local", "reliable")
func load_game_scene(_scene: String):
	if !State.menu_scene:
		print("set the lobby scene")
		return

	State.current_state = State.GameState.IN_GAME

	# note:
	# using the normal get_tree().change_scene() just fucks up the whole multiplayerspawner/multiplayersynchronizer connection
	# manually adding the world node and hiding the lobby ui fixed it... (or maybe the load + instantiate this early?)
	# and apperently godot uses Capital letters in the tree even though scenes are saved in lowercase????
	# remove menu if it exists
	for child in get_tree().get_root().get_children():
		if child.scene_file_path == State.menu_scene.resource_path:
			child.queue_free()
			break
	
	# add game if not present
	var game_exists = false
	for child in get_tree().get_root().get_children():
		if child.scene_file_path == _scene:
			game_exists = true
			break
	
	if not game_exists:
		var game_instance = load(_scene).instantiate()
		get_tree().get_root().add_child(game_instance)


# this gets called on all peers when a new peer connects, such that
# everyone gets updated with the fact that a new peer is in the server
# this is registered to the State.lobby_data.peer_members dictionary
# on all clients
@rpc("any_peer")
func register_peer(_steam_id: int):
	var godot_id = multiplayer.get_remote_sender_id()
	State.lobby_data.peer_members[godot_id] = _steam_id
	print("Godot ID: ", godot_id, " | Steam ID: ", _steam_id)

#TODO: might have to make the unregister peer an rpc too?
