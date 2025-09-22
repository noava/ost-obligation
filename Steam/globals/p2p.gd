extends Node

const PORT = 13154

var peer: SteamMultiplayerPeer

func _ready() -> void:
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	#multiplayer.server_disconnected.connect(somethinghere)

#####################
###### HELPERS ######
#####################
func create_socket():
	peer = SteamMultiplayerPeer.new()
	peer.create_host(0)
	multiplayer.set_multiplayer_peer(peer)
	#add the host itself to the peer list
	State.lobby_data.peer_members[1] = State.user_data.steam_id
	print("establishing connection (host)")

func connect_socket(_id: int):
	peer = SteamMultiplayerPeer.new()
	peer.create_client(_id, 0)
	multiplayer.set_multiplayer_peer(peer)
	print("establishing connection (client)")

func remove_peer(_id):
	State.lobby_data.peer_members.erase(_id)
	print("player with peer id: " + str(_id) + " left....")

func start_game(_scene):
	if not multiplayer.is_server():
		return
	load_game_scene.rpc(_scene)


#######################
###### CALLBACKS ######
#######################
func _connected_ok():
	print("_connected_ok")

func _connected_fail():
	print("connected_fail")
	multiplayer.set_multiplayer_peer(null)

func _player_disconnected(_id):
	print("disconnected")
	remove_peer(_id)
	
func _player_connected(_id):
	print("_player_connected")
	var my_steam_id = Steam.getSteamID()
	register_peer.rpc_id(_id, my_steam_id)


###################
###### RPC's ######
###################
@rpc("call_local", "reliable")
func load_game_scene(_scene: String):
	print("ok loading")
	# note:
	# using the normal get_tree().change_scene() just fucks up the whole multiplayerspawner/multiplayersynchronizer connection
	# manually adding the world node and hiding the lobby ui fixed it... (or maybe the load + instantiate this early?)
	var game = load(_scene).instantiate()
	get_tree().get_root().add_child(game)
	get_tree().get_root().get_node("Lobby").hide() #ALERT: ADD LOBBY ROOT NODE IDENTIFIER HERE <- 

@rpc("any_peer")
func register_peer(_steam_id: int):
	var godot_id = multiplayer.get_remote_sender_id()
	State.lobby_data.peer_members[godot_id] = _steam_id
	print("Godot ID: ", godot_id, " | Steam ID: ", _steam_id)
