extends Node3D
@onready var players: Node3D = $Players

func _ready() -> void:
	spawn_players()

func spawn_players():
	const character = preload("uid://vgsou12k4ck")
	
	# single player
	if State.single_player:
		print("spawning as singleplayer")
		players.add_child(character.instantiate())
	
	# if owner and multiplayer
	if State.user_data.steam_id == State.lobby_data.owner_id:
		print("spawning as multiplayer")
		for peer in State.lobby_data.peer_members:
			var player = character.instantiate()
			player.name = str(peer)
			player.position = players.position
			players.add_child(player, true)
