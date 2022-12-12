extends Node


const FORM_TYPE := "Content-Type: application/x-www-form-urlencoded"
const RENEWAL_INTERVAL := 1600

signal new_leaderboard_entry(entry)
signal account_retrieved
signal login_succeeded
signal login_connection_failed
signal login_bad_credentials
# warning-ignore:unused_signal
signal login_required

var account_data: AccountData
var username: String
var session_key: String
var _endless_highscores := PoolIntArray([0, 0, 0])
var _renewal_ended := false

var _renewal_timer: Timer
var _ws_poller: Timer
var _leaderboard_ws: WebSocketClient
var _leaderboard_ws_had_error := false
var sync_leaderboard := false setget set_sync_leaderboard


func set_sync_leaderboard(value: bool):
	if value == sync_leaderboard:
		return
	
	sync_leaderboard = value
	
	if !value:
		_leaderboard_ws.disconnect_from_host()
		return
	
	_leaderboard_ws = WebSocketClient.new()
	var err := _leaderboard_ws.connect_to_url("wss://manglemix.com/ws/bola/leaderboards")
	
	_leaderboard_ws_had_error = err != OK
	
	# warning-ignore:return_value_discarded
	_leaderboard_ws.connect("data_received", self, "_get_leaderboard_data")
	# warning-ignore:return_value_discarded
	_ws_poller.connect("timeout", _leaderboard_ws, "poll")


func is_logged_in() -> bool:
	return !session_key.empty()
	


func login(password: String):
	if _make_api_req(
		"/api/login",
		"_on_login_completed",
		HTTPClient.METHOD_POST,
		"username=" + username + "&password=" + password,
		[FORM_TYPE],
		false
	) != OK:
		emit_signal("login_connection_failed")


func _on_login_completed(result: int, response_code: int, _headers: PoolStringArray, body: PoolByteArray):
	if result != OK:
		emit_signal("login_connection_failed")
		return
	
	if response_code == HTTPClient.RESPONSE_OK:
		_renewal_ended = false
		session_key = body.get_string_from_utf8()
		_renewal_timer.start()
		
	# warning-ignore:return_value_discarded
		_make_api_req(
			"/api/bola/account",
			"_on_get_account",
			HTTPClient.METHOD_GET,
			"",
			[],
			true
		)
		
		emit_signal("login_succeeded")
	
	elif response_code == HTTPClient.RESPONSE_UNAUTHORIZED or response_code == HTTPClient.RESPONSE_BAD_REQUEST:
		emit_signal("login_bad_credentials")
		return
	
	else:
		print_debug("Unexpected response_code: ", response_code)


class AccountData extends Reference:
	var easy_highscore: int
	var normal_highscore: int
	var expert_highscore: int
	var tournament_wins: int


func _on_get_account(result: int, response_code: int, _headers: PoolStringArray, body: PoolByteArray):
	if result != OK:
		return
	
	if response_code == HTTPClient.RESPONSE_OK:
		var raw_data: Dictionary = parse_json(body.get_string_from_utf8())
		account_data = AccountData.new()
		account_data.easy_highscore = raw_data["easy_max_level"]
		account_data.normal_highscore = raw_data["normal_max_level"]
		account_data.expert_highscore = raw_data["hard_max_level"]
		account_data.tournament_wins = raw_data["tournament_wins"]
		Tournament.won_tournament = raw_data["won_tournament"]
		emit_signal("account_retrieved")
	
	else:
		print_debug("Unexpected response_code: ", response_code)


func win_tournament(current_week: int):
	# warning-ignore:return_value_discarded
	print_debug("Tournament win sent")
	_make_api_req(
		"/api/bola/tournament",
		"",
		HTTPClient.METHOD_POST,
		"week=" + str(current_week),
		[FORM_TYPE],
		true
	)


func add_leaderboard_entry(difficulty: int, levels: int):
	if account_data == null:
		return
	
	match difficulty:
		1:
			if levels > account_data.easy_highscore:
				account_data.easy_highscore = levels
			else:
				return
		2:
			if levels > account_data.normal_highscore:
				account_data.normal_highscore = levels
			else:
				return
		3:
			if levels > account_data.expert_highscore:
				account_data.expert_highscore = levels
			else:
				return
		
	# warning-ignore:return_value_discarded
	_make_api_req(
		"/api/bola/leaderboard/endless",
		"",
		HTTPClient.METHOD_POST,
		"difficulty=" + str(difficulty) + "&levels=" + str(levels),
		[FORM_TYPE],
		true
	)


func _on_response_debug(result: int, response_code: int, _headers: PoolStringArray, body: PoolByteArray):
	if result != OK:
		return
	
	if response_code != HTTPClient.RESPONSE_OK:
		print_debug(body.get_string_from_utf8())
		print_debug("Unexpected response_code: ", response_code)


func _ready():
	_ws_poller = Timer.new()
	_ws_poller.wait_time = 0.1
	_ws_poller.autostart = true
	add_child(_ws_poller)
	_renewal_timer = Timer.new()
	_renewal_timer.wait_time = RENEWAL_INTERVAL
	_renewal_timer.one_shot = true
	add_child(_renewal_timer)
	
	# warning-ignore:return_value_discarded
	_make_api_req(
		"/api/bola/tournament",
		"_on_tournament_received",
		HTTPClient.METHOD_GET,
		"",
		[],
		false
	)


func _on_tournament_received(result: int, response_code: int, _headers: PoolStringArray, body: PoolByteArray):
	if result != OK:
		return
	
	if response_code != HTTPClient.RESPONSE_OK:
		print_debug("Unexpected error code: " + str(response_code) + " while getting tournament")
		return
	
	var data: Dictionary = parse_json(body.get_string_from_utf8())
	Tournament.initialize(data["week"], data["seed"], data["since"], data["until"])


func _renew_session():
	if _renewal_ended:
		session_key = ""
		account_data = null
		return
	
	# warning-ignore:return_value_discarded
	_make_api_req(
		"/api/renew_session",
		"_on_session_renew",
		HTTPClient.METHOD_POST,
		"",
		[],
		true
	)


func _on_session_renew(result: int, response_code: int, _headers: PoolStringArray, body: PoolByteArray):
	if result != OK:
		return
	
	if response_code == HTTPClient.RESPONSE_OK:
		var msg := body.get_string_from_utf8()
		if !msg.is_valid_integer():
			return
		var remaining := int(msg)
		
		_renewal_timer.start()
		
		if remaining == 0:
			_renewal_ended = true
	
	else:
		print_debug("Unexpected response_code: ", response_code)


class LeaderboardEntryData extends Reference:
	var username: String
	var difficulty: int
	var levels: int


func _get_leaderboard_data():
	var message := _leaderboard_ws.get_peer(1).get_packet().get_string_from_utf8()
	var parsed = parse_json(message)
	
	var arr
	if parsed is Array:
		arr = parsed
	else:
		arr = [parsed]
	
	for item in arr:
		var entry := LeaderboardEntryData.new()
		entry.username = item["username"]
		entry.difficulty = item["difficulty"]
		entry.levels = item["levels"]
		emit_signal("new_leaderboard_entry", entry)


func _make_api_req(path: String, callback: String, method: int, body: String, headers: Array, with_key: bool) -> int:
	if with_key:
		if session_key.empty():
			return -1
		headers.append("Session-Key: " + session_key)
	
	var request := _make_http_node()
	if callback.empty():
		callback = "_on_response_debug"
	# warning-ignore:return_value_discarded
	request.connect("request_completed", self, callback)
	
	var err := request.request(
		"https://manglemix.com" + path,
		headers,
		true,
		method,
		body
	)
	
	if err != OK:
		print_debug("Error code: " + str(err) + " while sending request")
	
	return err


func _make_http_node() -> HTTPRequest:
	var request := HTTPRequest.new()
	request.timeout = 5
	add_child(request)
	return request
