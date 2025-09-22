extends SteamHandler

@onready var lobbiesbox = $PopupPanel/Lobbies/Scroll/LobbiesBox
@onready var lobbiestitle = $PopupPanel/Lobbies/LobbiesTitle
@onready var playerstitle = $InLobby/Players/PlayersTitle
@onready var messagebox = $InLobby/Message/MessageBox
@onready var playersbox = $InLobby/Players/PlayersBox
@onready var lobbytitle = $InLobby/Chat/LobbyTitle
@onready var chatbox = $InLobby/Chat/ChatBox
@onready var leave = $InLobby/Leave
@onready var start = $InLobby/Start
@onready var popup = $PopupPanel
@onready var inlobby = $InLobby
@onready var browse = $Browse
@onready var host = $Host
@onready var back = $Back

func _ready() -> void:
	SteamManager.register_handler(self)

	# if the player accepted an invite
	if State.lobby_data.id != 0:
		show_lobby()
		populate_player_list()


###################################################
##################### HELPERS #####################
###################################################
func reset_lobby():
	playersbox.clear()
	playerstitle.text = "Players: (1)"
	chatbox.clear()
	messagebox.clear()

func hide_lobby():
	chatbox.clear()
	host.show()
	inlobby.hide()
	browse.show()
	back.show()
	leave.hide()
	start.hide()

func show_lobby():
	inlobby.show()
	host.hide()
	browse.hide()
	back.hide()
	leave.show()
	start.show()

func populate_player_list():
	var _players = SteamManager.get_lobby_members()
	playersbox.clear()
	for player in _players.values():
		print(player)
		playersbox.add_text(player.steam_username + "\n")
	playerstitle.text = "players: (" + str(_players.size()) + ")"


#######################################################
##################### INTERACTION #####################
#######################################################
func _on_back_pressed():
	get_tree().change_scene_to_file("res://main.tscn")

func _on_host_pressed():
	show_lobby()
	SteamManager.create_lobby()

func _on_browse_pressed():
	popup.show()
	SteamManager.search_available_lobbies()
	lobbiestitle.text = "Loading lobbies..."

func _on_leave_pressed():
	hide_lobby()
	SteamManager.leave_current_lobby()

func _on_message_box_gui_input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		var message = messagebox.text
		if message == "":
			return
		
		SteamManager.send_chat_message(message)
		messagebox.clear()
		get_viewport().set_input_as_handled()

func _on_start_pressed():
	SteamManager.load_scene_for_all(State.game_scene)

## these are for the browse popup
func _on_close_pressed():
	popup.hide()
	pass # Replace with function body.


#####################################################
##################### ABSTRACTS #####################
#####################################################

func on_chat_message(_sender, _message):
	chatbox.append_text(_sender + ": " + _message + "\n")

func on_system_message(_message):
	chatbox.append_text("system: " + _message + "\n")
	populate_player_list()

func on_lobby_created(_lobby_id, _name):
	show_lobby()
	chatbox.append_text("lobby with id: " + str(_lobby_id) + " created\n")
	lobbytitle.text = _name

func on_lobby_joined(_lobby_id, _name):
	show_lobby()
	start.hide()
	chatbox.append_text("joined lobby: " + str(_lobby_id) + "\n")
	lobbytitle.text = _name

func on_lobbies_found(_lobbies):
	for n in lobbiesbox.get_children():
		lobbiesbox.remove_child(n)
		n.queue_free()
	
	for this_lobby in _lobbies:
		# Pull lobby data from Steam, these are specific to our example
		var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
		var lobby_mode: String = Steam.getLobbyData(this_lobby, "mode")

		# Get the current number of members
		var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)

		# Create a button for the lobby
		var lobby_button: Button = Button.new()
		lobby_button.set_text("Lobby %s: [%s] - %s Player(s)" % [lobby_name, lobby_mode, lobby_num_members])
		lobby_button.set_size(Vector2(800, 50))
		lobby_button.set_name("lobby_%s" % this_lobby)
		lobby_button.connect("pressed", func():
			SteamManager.join_lobby(this_lobby)
			popup.hide()
		)
		
		# Add the new lobby to the list
		lobbiesbox.add_child(lobby_button)
	lobbiestitle.text = "Lobbies: (" + str(_lobbies.size()) + ")" 
