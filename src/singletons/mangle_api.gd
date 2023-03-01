extends Node

const ENDPOINTS := ["wss://bola.us1.manglemix.com/ws_api", "wss://bola.sea1.manglemix.com/ws_api"]
const RETRY_DELAY := 3.0

signal _data_received_or_event
signal _connection_attempted(ok)
signal _username_received
signal username_needed(msg)
signal connected
signal already_connected
signal leaderboard_update

var ws: WebSocketClient
var is_logged_in := false
var logging_in := false
var account_data := AccountData.new()
var _login_token: String
var connected := false
var watching_leaderboard := false

var easy_leaderboard: Array
var normal_leaderboard: Array
var expert_leaderboard: Array

var _tmp_msg: PoolByteArray


func _ready():
	var file := File.new()
	if file.open_encrypted_with_pass("user://login_token", File.READ, _get_api_token()) == OK:
		_login_token = file.get_pascal_string()
	_reconnect()


func login():
	if not connected or is_logged_in:
		return
	
	logging_in = true
	# warning-ignore:return_value_discarded
	_send_message("\"Login\"")
	
	var msg = yield(_recv_message(), "completed")
	if msg == null:
		return
	# warning-ignore:return_value_discarded
	OS.shell_open(msg)
	
	msg = yield(_recv_message(), "completed")
	if msg == null or msg == "Login Cancelled":
		logging_in = false
		return
	
	var user_profile_msg = ""
	if msg == "Sign Up":
		emit_signal("username_needed", "")
		while true:
			yield(self, "_username_received")
			var data := {"username": account_data.username}
			if account_data.easy_highscore > 0:
				data["easy_highscore"] = account_data.easy_highscore
			if account_data.normal_highscore > 0:
				data["normal_highscore"] = account_data.normal_highscore
			if account_data.expert_highscore > 0:
				data["expert_highscore"] = account_data.expert_highscore
			_send_message(to_json(data))
			msg = yield(_recv_message(), "completed")
			if msg == null:
				logging_in = false
				return
			if msg == "Success":
				break
			else:
				emit_signal("username_needed", msg)
	else:
		user_profile_msg = msg
	
	_login_token = yield(_recv_message(), "completed")
	var file := File.new()
	if file.open_encrypted_with_pass("user://login_token", File.WRITE, _get_api_token()) == OK:
		file.store_pascal_string(_login_token)
	
	is_logged_in = true
	logging_in = false
	if !user_profile_msg.empty():
		_read_user_profile(user_profile_msg)


func cancel_login():
	if not logging_in:
		return
	# warning-ignore:return_value_discarded
	_send_message("Cancel")


func provide_username(username: String):
	account_data.username = username
	emit_signal("_username_received")


func logout():
	if not connected or not is_logged_in:
		return
	
	# warning-ignore:return_value_discarded
	_send_message("\"Logout\"")
	yield(_recv_message(), "completed")
	is_logged_in = false
	_login_token = ""
	account_data = AccountData.new()
	var dir := Directory.new()
	if dir.open("user://") != OK:
		push_error("Unable to open user://")
		return
	if dir.file_exists("login_token") and dir.remove("login_token") != OK:
		push_error("Unable to delete login_token")


func watch_leaderboard():
	watching_leaderboard = true
	_send_message("\"GetLeaderboard\"")
	ws.connect("data_received", self, "_on_leaderboard_update")


func cancel_watch_leaderboard():
	if not watching_leaderboard:
		return
	_send_message("Cancel")


func add_leaderboard_entry(difficulty: String, score: int):
	match difficulty:
		"easy":
			account_data.easy_highscore = score
		"normal":
			account_data.normal_highscore = score
		"expert":
			account_data.expert_highscore = score
		_:
			push_error("Unexpected difficulty: %s" % difficulty)
			return
	
	if is_logged_in:
		_send_message(
			"{\"ScoreUpdateRequest\":{\"difficulty\":\"%s\",\"score\":%s}}" % [difficulty, score]
		)
		var msg = yield(_recv_message(), "completed")
		if msg != null and msg != "Success":
			push_error("Faced the following error while updating leaderboard: %s" % msg)


func win_tournament(week_number: int):
	if week_number in account_data.tournament_wins:
		return
	account_data.tournament_wins.append(week_number)
	_send_message("\"WinTournament\"")
	var msg = yield(_recv_message(), "completed")
	if msg != null and msg != "Success":
		push_error("Faced the following error while winning tournament: %s" % msg)


func _on_connection_closed(_was_clean):
	push_error("API Connection Lost")
	emit_signal("_data_received_or_event")
	_reconnect()


func _on_server_close_request(code: int, reason: String):
	push_error("Server close request code: %s, reason: %s" % [code, reason])
	if reason == "Already Connected":
		emit_signal("already_connected")
	var _tmp_ws = ws
	ws = null
	yield(_tmp_ws, "connection_closed")


func _send_message(msg: String) -> bool:
	if ws == null:
		return false
	var err := ws.get_peer(1).put_packet(msg.to_utf8())
	if err != OK:
		push_error("Could not send packet: " + str(err))
		return false
	return true


func _recv_message() -> String:
	yield(self, "_data_received_or_event")
	if ws == null:
		return null
	return ws.get_peer(1).get_packet().get_string_from_utf8()


func _exit_tree():
	if ws != null:
		ws.disconnect_from_host()


func _reconnect():
	is_logged_in = false
	connected = false
	if ws != null:
		ws.disconnect_from_host()
		ws = null
	
	while true:
		ws = WebSocketClient.new()
		var url: String
		if Engine.editor_hint:
			url = ProjectSettings.get_setting("constants/debug_data/route")
		else:
			url = ENDPOINTS[0]
#		var url: String = ProjectSettings.get_setting("constants/debug_data/route")
		url += "?api_token=" + _get_api_token()
		
		if !_login_token.empty():
			url += "&login-token=" + _login_token 
		
		# warning-ignore-all:return_value_discarded
		ws.connect("connection_error", self, "_on_connection_error", [], CONNECT_ONESHOT)
		ws.connect("connection_established", self, "_on_connection_established", [], CONNECT_ONESHOT)
		get_tree().connect("idle_frame", ws, "poll")
		
		if ws.connect_to_url(url) == OK:
			if yield(self, "_connection_attempted"):
				break
		else:
			ws = null
		
		if !_login_token.empty():
			_login_token = ""
		yield(get_tree().create_timer(RETRY_DELAY), "timeout")
	
	ws.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	ws.disconnect("connection_error", self, "_on_connection_error")
	ws.connect("data_received", self, "emit_signal", ["_data_received_or_event"])
	ws.connect("connection_closed", self, "_on_connection_closed")
	ws.connect("server_close_request", self, "_on_server_close_request")
	
	if !_login_token.empty():
		var res = yield(_recv_message(), "completed")
		if res == null:
			return
		_read_user_profile(res)
		yield(init_tournament(true), "completed")
		is_logged_in = true
		connected = true
		emit_signal("connected")
		return
	
	yield(init_tournament(true), "completed")
	connected = true
	emit_signal("connected")


func init_tournament(force:=false):
	if not force and not connected:
		yield(self, "connected")
	
	_send_message("\"GetTournament\"")
	var res = yield(_recv_message(), "completed")
	if res == null:
		return
	var data: Dictionary = parse_json(res)
	Tournament.initialize(data["week"], data["seed"], data["start_time"], data["end_time"])


func _on_connection_established(_protocol):
	emit_signal("_connection_attempted", true)


func _on_connection_error():
	emit_signal("_connection_attempted", false)


func _get_api_token() -> String:
	return ProjectSettings.get_setting("api/auth/api_token")


func _read_user_profile(msg: String):
	var user_profile: Dictionary = parse_json(msg)
	
	var new_account_data = AccountData.new()
	new_account_data.username = user_profile["username"]
	new_account_data.easy_highscore = user_profile["easy_highscore"]
	new_account_data.normal_highscore = user_profile["normal_highscore"]
	new_account_data.expert_highscore = user_profile["expert_highscore"]
	new_account_data.tournament_wins = user_profile["tournament_wins"]
	
	if account_data.easy_highscore > new_account_data.easy_highscore:
		new_account_data.easy_highscore = account_data.easy_highscore
		add_leaderboard_entry("easy", account_data.easy_highscore)
		
	if account_data.normal_highscore > new_account_data.normal_highscore:
		new_account_data.normal_highscore = account_data.normal_highscore
		add_leaderboard_entry("normal", account_data.normal_highscore)
		
	if account_data.expert_highscore > new_account_data.expert_highscore:
		new_account_data.expert_highscore = account_data.expert_highscore
		add_leaderboard_entry("expert", account_data.expert_highscore)
	
	account_data = new_account_data


func _on_leaderboard_update():
	var msg := ws.get_peer(1).get_packet().get_string_from_utf8()
	if msg == "Unsubscribed":
		watching_leaderboard = false
		ws.disconnect("data_received", self, "_on_leaderboard_update")
		return
	var data: Dictionary = parse_json(msg)
	if data.has("easy"):
		easy_leaderboard = data["easy"]
	if data.has("normal"):
		normal_leaderboard = data["normal"]
	if data.has("expert"):
		expert_leaderboard = data["expert"]
	emit_signal("leaderboard_update")
