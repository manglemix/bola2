extends Node


signal _sdp_created
signal new_multiplayer_session(session)

var _tmp_sdp: String
var _rtc: WebRTCPeerConnection
var _multiplayer_session_ws: WebSocketClient
var _multiplayer_sessions_ws_had_error := false
var sync_multiplayer_sessions := false setget set_sync_multiplayer_sessions


func set_sync_multiplayer_sessions(value: bool):
	if value == sync_multiplayer_sessions:
		return
	
	sync_multiplayer_sessions = value
	
	if !value:
		_multiplayer_session_ws.disconnect_from_host()
		return
	
	_multiplayer_session_ws = WebSocketClient.new()
	var err := _multiplayer_session_ws.connect_to_url("wss://manglemix.com/ws/bola/multiplayer")
	
	_multiplayer_sessions_ws_had_error = err != OK
	
	# warning-ignore:return_value_discarded
	_multiplayer_session_ws.connect("data_received", self, "_on_multiplayer_sessions_data")
	WsPoller.poll_ws(_multiplayer_session_ws)


class CreateRoomRequest:
	var type: String
	var room_name: String
	var sdp: String


class JoinRoomRequest:
	var type: String
	var room_name: String
	var sdp: String
	var password: String


func create_multiplayer_room(type: String, room_name: String):
	if !sync_multiplayer_sessions:
		print_debug("Attempted to make room while not synced!")
		return
	
	_rtc = WebRTCPeerConnection.new()
	var channel := _rtc.create_data_channel(
		"main",
		{
			"maxRetransmits": 0, # Specify the maximum number of attempt the peer will make to retransmits packets if they are not acknowledged.
			"ordered": false, # When in unreliable mode (i.e. either "maxRetransmits" or "maxPacketLifetime" is set), "ordered" (true by default) specify if packet ordering is to be enforced.
		}
	)
	
	if channel == null:
		print_debug("Could not create data channel")
		return
	
	_tmp_sdp = ""
	_rtc.connect("session_description_created", self, "_on_sdp_created")
	if _rtc.create_offer() != OK:
		print_debug("Could not create offer")
		return
	
	if _tmp_sdp.empty():
		yield(self, "_sdp_created")
	
	var req := CreateRoomRequest.new()
	req.type = type
	req.room_name = room_name
	req.sdp = _tmp_sdp
	
	if _multiplayer_session_ws.put_packet(to_json(req).to_utf8()) != OK:
		print_debug("Could not send offer")


func _on_sdp_created(type: String, sdp: String):
	_tmp_sdp = sdp
	_rtc.set_local_description(type, sdp)
	emit_signal("_sdp_created")


class MultiplayerSession:
	var type: String
	var room_name: String


class ICEExchange:
	var ice: String


func _on_multiplayer_sessions_data():
	var message := _multiplayer_session_ws.get_peer(1).get_packet().get_string_from_utf8()
	var parsed = parse_json(message)
	
	var arr
	if parsed is Array:
		arr = parsed
	else:
		arr = [parsed]
	
	for item in arr:
		var entry := MultiplayerSession.new()
		entry.type = item["type"]
		entry.room_name = item["room_name"]
		emit_signal("new_multiplayer_session", entry)
