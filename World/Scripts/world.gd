extends SessionHandler

@onready var players: Node3D = $Players
const character = preload("uid://vgsou12k4ck")

func _ready() -> void:
	if State.single_player:
		print("spawning as singleplayer")
		players.add_child(character.instantiate())
	else:
		SteamManager.register_handler(self)

func _exit_tree() -> void:
	SteamManager.unregister_handler(self)


# called only by multiplayer (the host only)
func on_game_start(peers: Array) -> void:
	print("game started with peers: " + str(peers))
	for peer in peers:
		var player = character.instantiate()
		player.name = str(peer)
		player.position = players.position
		players.add_child(player, true)


# happens only when a player joins mid game (since this script is not loaded before)
func on_player_join(peer: int) -> void:
	print("player joined: " + str(peer))
	var player = character.instantiate()
	player.name = str(peer)
	player.position = players.position
	players.add_child(player, true)


# happens only when a player leaves mid game
func on_player_leave(peer: int) -> void:
	print("player left: " + str(peer))
	var peer_id = str(peer)
	if players.has_node(peer_id):
		players.get_node(peer_id).queue_free()
	else:
		print("could not find player with peer id: " + peer_id)


