extends Node

const APP_ID: int = 480
const PRIVATE_LOBBY = 0
const FRIENDS_ONLY_LOBBY = 1
const PUBLIC_LOBBY = 2
const INVISIBLE_LOBBY = 3

const CLOSE_DISTANCE = 0
const DEFAULT_DISTANCE = 1
const FAR_DISTANCE = 2
const WORLDWIDE_DISTANCE = 3

var _handlers: Array[SteamHandler] = []

########################################################
####################### INITIALS #######################
########################################################
func _ready() -> void:
	initialize_steam()
	check_command_line()
	
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_message.connect(_on_lobby_send_msg)
	Steam.join_requested.connect(_on_lobby_join_requested)


func initialize_steam() -> void:
	#since the steamgodot extension hasnt updated yet?
	#var app_id = OS.get_environment("SteamAppId").to_int()
	#if app_id == 0:
		#print("make sure to set the app id in the godot:")
		#print("editor > project settings > steam > app id (480)")
		#print("also make sure to enable callback while you are there.")
	
	
	var init: Dictionary = Steam.steamInitEx(APP_ID, true)
	if init['status'] > Steam.STEAM_API_INIT_RESULT_OK:
		print("Failed to initialize steam: ", init)
		get_tree().quit()
	
	var steam_id = Steam.getSteamID()
	var steam_username = Steam.getPersonaName()
	var owned: bool = Steam.isSubscribed()
	
	State.user_data.steam_id = steam_id
	State.user_data.steam_username = steam_username
	
	if not owned:
		print("the user does not own this game")
		get_tree().quit()

####################################################################
####################### HANDLER SUBSCRIPTION #######################
####################################################################

func register_handler(_handler: SteamHandler):
	_handlers.append(_handler)

func unregister_handler(_handler: SteamHandler):
	_handlers.erase(_handler)

func notify_handlers(_method: StringName, ...args: Array):
	for handler in _handlers:
		handler.callv(_method, args)

####################################################################
####################### STEAMLOBBY FUNCTIONS #######################
####################################################################
func create_lobby(_lobby_name: String = "", _max_players: int = 10):
	if State.lobby_data.id != 0:
		return
	if _lobby_name == "":
		_lobby_name = State.user_data.steam_username + "'s lobby:"
	State.lobby_data.name = _lobby_name
	Steam.createLobby(PUBLIC_LOBBY, _max_players)

func join_lobby(_lobby_id: int):
	State.lobby_data.id = _lobby_id
	Steam.joinLobby(_lobby_id)

func leave_lobby(_lobby_id: int):
	if State.lobby_data.id == 0:
		return
	
	Steam.leaveLobby(_lobby_id)
	State.lobby_data.id = 0
	
	for member in State.lobby_data.members:
		Steam.closeP2PSessionWithUser(member)
	
	State.lobby_data.members.clear()
	print("left")

func leave_current_lobby():
	leave_lobby(State.lobby_data.id)

func search_available_lobbies():
	Steam.addRequestLobbyListDistanceFilter(CLOSE_DISTANCE)
	Steam.requestLobbyList()

func send_chat_message(_message):
	var lobby_id = State.lobby_data.id
	var username = State.user_data.steam_username
	Steam.sendLobbyChatMsg(lobby_id, _message)
	# call the signal for normal message here too so the local ui see the message instantly
	notify_handlers("on_chat_message", username, _message)

func get_lobby_members(_lobby_id: int = -1):
	if _lobby_id == -1:
		_lobby_id = State.lobby_data.id
	elif _lobby_id == 0:
		return
	
	var members_nr = Steam.getNumLobbyMembers(_lobby_id)
	var players = {}
	
	for member in range(0, members_nr):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(_lobby_id, member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		players[member_steam_id] = {"steam_id" : member_steam_id, "steam_username": member_steam_name}
	
	State.lobby_data.members.clear()
	State.lobby_data.members = players
	return players

####################################################################
####################### STEAM PEER FUNCTIONS #######################
####################################################################

func load_scene_for_all(_scene: String):
	p2p.start_game(_scene)

#########################################################
####################### CALLBACKS #######################
#########################################################
func _on_lobby_created(_connect: int, _lobby_id: int):
	if _connect != 1:
		return
	
	State.lobby_data.id = _lobby_id
	Steam.setLobbyData(_lobby_id, "name", State.lobby_data.name)
	p2p.create_socket()

	notify_handlers("on_lobby_created", _lobby_id, State.lobby_data.name)

func _on_lobby_joined(_lobby_id: int, _permissions: int, _locked: bool, response: int):
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		return
	
	var _name = Steam.getLobbyData(_lobby_id, "name")
	var _owner = Steam.getLobbyOwner(_lobby_id)
	
	State.lobby_data.name = _name
	State.lobby_data.owner_id = _owner
	
	if State.user_data.steam_id != _owner:
		p2p.connect_socket(_owner)
		notify_handlers("on_lobby_joined", _lobby_id, _name)

func _on_lobby_chat_update(_lobby_id: int, _change_id: int, _making_change_id: int, _chat_state: int) -> void:
	# Get the user who has made the lobby change
	var changer_name: String = Steam.getFriendPersonaName(_change_id)
	var message: String = ""
	
	match _chat_state:
		Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
			message = "%s has joined the lobby." % changer_name
		Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
			message = "%s has left the lobby." % changer_name
		Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
			message = "%s has been kicked from the lobby." % changer_name
		Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
			message = "%s has been banned from the lobby." % changer_name
		_: # Else there was some unknown change
			message = "%s did... something." % changer_name
	
	notify_handlers("on_system_message", message)

#TODO: not sure here yet
func _on_lobby_data_update(_success, _lobby_id, _member_id):
	print("lobby update??")

# this will most likely just be a direct passthrough
func _on_lobby_match_list(_lobbies: Array):
	notify_handlers("on_lobbies_found", _lobbies)

func _on_lobby_send_msg(_result, _user, _message, _type):
	# avoid getting ur own message
	if _user == State.user_data.steam_id:
		return
	var sender = Steam.getFriendPersonaName(_user)
	notify_handlers("on_chat_message", sender, _message)

# this is to handle the join reqeusts in steam? (like after getting invited)
func _on_lobby_join_requested(_lobby_id: int, _friend_id: int):
	assert(
		State.lobby_scene.contains(".tscn"), 
		"the lobby scene is not set in state.gd"
	)
	get_tree().change_scene_to_file(State.lobby_scene)
	State.single_player = false
	var steam_name = Steam.getFriendPersonaName(_friend_id)
	print("joining..." + steam_name)
	join_lobby(_lobby_id)

############################################################
####################### COMMAND LINE #######################
############################################################
func check_command_line() -> void:
	var these_arguments: Array = OS.get_cmdline_args()

	# There are arguments to process
	if these_arguments.size() > 0:

		# A Steam connection argument exists
		if these_arguments[0] == "+connect_lobby":

			# Lobby invite exists so try to connect to it
			if int(these_arguments[1]) > 0:

				# At this point, you'll probably want to change scenes
				# Something like a loading into lobby screen
				print("Command line lobby ID: %s" % these_arguments[1])
				
				var id = int(these_arguments[1])
				State.lobby_data.id = id
				assert(
					State.lobby_scene.contains(".tscn"), 
					"the lobby scene is not set in state.gd"
				)
				get_tree().change_scene_to_file(State.lobby_scene)
				join_lobby(id)
