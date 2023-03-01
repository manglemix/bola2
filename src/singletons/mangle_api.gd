extends Node

const RETRY_DELAY := 3.0

signal _data_received_or_event
signal _connection_attempted(ok)
signal connected
signal leaderboard_update

var ws: WebSocketClient
var is_logged_in := false
var logging_in := false
var account_data: AccountData
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
	_send_message("\"Login\"".to_utf8())
	
	var msg = yield(_recv_message(), "completed")
	if msg == null:
		return
	# warning-ignore:return_value_discarded
	OS.shell_open(msg)
	
	msg = yield(_recv_message(), "completed")
	if msg == null or msg == "Login Cancelled":
		logging_in = false
		return
	
	assert(msg != "Sign Up")
	
	_read_user_profile(msg)
	
	_login_token = yield(_recv_message(), "completed")
	var file := File.new()
	if file.open_encrypted_with_pass("user://login_token", File.WRITE, _get_api_token()) == OK:
		file.store_pascal_string(_login_token)
	
	is_logged_in = true
	logging_in = false


func cancel_login():
	if not logging_in:
		return
	# warning-ignore:return_value_discarded
	_send_message("Cancel".to_utf8())


func logout():
	if not connected or not is_logged_in:
		return
	
	# warning-ignore:return_value_discarded
	_send_message("\"Logout\"".to_utf8())
	yield(_recv_message(), "completed")
	is_logged_in = false
	_login_token = ""
	account_data = null
	var dir := Directory.new()
	if dir.open("user://") != OK:
		push_error("Unable to open user://")
		return
	if dir.file_exists("login_token") and dir.remove("login_token") != OK:
		push_error("Unable to delete login_token")


func watch_leaderboard(refresh:=true):
	watching_leaderboard = true
	var req := "{\"GetLeaderboard\":{"
	if refresh:
		req += "\"refresh\":true"
	req += "}}"
	_send_message(req.to_utf8())
	ws.connect("data_received", self, "_on_leaderboard_update")


func cancel_watch_leaderboard():
	if not watching_leaderboard:
		return
	_send_message("Cancel".to_utf8())


func _on_connection_closed(_was_clean):
	emit_signal("_data_received_or_event")
	_reconnect()


func _send_message(msg: PoolByteArray) -> bool:
	if ws == null:
		return false
	var err := ws.get_peer(1).put_packet(msg)
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
		var url: String = ProjectSettings.get_setting("api/websocket/route")
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
	
	if !_login_token.empty():
		var res = yield(_recv_message(), "completed")
		if res == null:
			return
		_read_user_profile(res)
		is_logged_in = true
		connected = true
		emit_signal("connected")
		return
	
	connected = true
	emit_signal("connected")


func _on_connection_established(_protocol):
	emit_signal("_connection_attempted", true)


func _on_connection_error():
	emit_signal("_connection_attempted", false)


func _get_api_token() -> String:
	return ProjectSettings.get_setting("api/auth/api_token")


func _read_user_profile(msg: String):
	var user_profile: Dictionary = JSON.parse(msg).result
	account_data = AccountData.new()
	account_data.username = user_profile["username"]
	account_data.easy_highscore = user_profile["easy_highscore"]
	account_data.normal_highscore = user_profile["normal_highscore"]
	account_data.expert_highscore = user_profile["expert_highscore"]
	account_data.tournament_wins = user_profile["tournament_wins"]


func _on_leaderboard_update():
	var msg := ws.get_peer(1).get_packet().get_string_from_utf8()
	if msg == "Unsubscribed":
		watching_leaderboard = false
		ws.disconnect("data_received", self, "_on_leaderboard_update")
		return
	var data: Dictionary = JSON.parse(msg).result
	if data.has("easy"):
		easy_leaderboard = data["easy"]
	if data.has("normal"):
		normal_leaderboard = data["normal"]
	if data.has("expert"):
		expert_leaderboard = data["expert"]
	emit_signal("leaderboard_update")
