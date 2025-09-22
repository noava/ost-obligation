extends Node
#https://godotsteam.com/tutorials/initializing/

var single_player: bool = true
var user_data: Dictionary = {
	"steam_id" : 0,
	"steam_username": ""
}
var lobby_data: Dictionary = {
	"owner_id": 0,
	"id": 0,
	"members": {}, # key: steam_id: {"steam_id" : member_steam_id, "steam_username": member_steam_name}
	"peer_members": {}, # key: peer_id: -> steam_id
	"name": "",	
	"lobby_size": 10
}

var game_scene: String = "res://world/game.tscn"
var lobby_scene: String = "res://steam/ui/lobby.tscn"
