extends Node


signal _rtc_attempt_finished(obj)
signal _ice_created(ice)

var my_peer: WebRTCPeerConnection


func host_session():
	if my_peer != null:
		my_peer.close()
	
	var multi_node := WebRTCMultiplayer.new()
	my_peer = WebRTCPeerConnection.new()
	
	var err := multi_node.add_peer(my_peer, 1)
	if err != OK:
		push_error("Unable to add my RTC peer: %s" % err)
		return
	
	err = multi_node.initialize(1, true)
	if err != OK:
		push_error("Unable to initialize my RTC peer: %s" % err)
		return
	
	my_peer.connect("session_description_created", self, "_on_offer_created")
	err = my_peer.create_offer()
	if err != OK:
		push_error("Unable to create rtc offer: %s" % err)
		return
	
	return yield(self, "_rtc_attempt_finished")


func _on_offer_created(type: String, sdp: String):
	assert(type == "offer")
	var err := my_peer.set_local_description(type, sdp)
	if err != OK:
		push_error("Unable to set local description: %s" % err)
		emit_signal("_rtc_attempt_finished", null)
		return
	
	var code = yield(MangleApi.host_session(sdp), "completed")
	if code.empty():
		emit_signal("_rtc_attempt_finished", null)
		return
	
	emit_signal("_rtc_attempt_finished", code)


func join_session(code: String) -> bool:
	var sdp = yield(MangleApi.join_session(code), "completed")
	if sdp == "":
		return false
	
	if my_peer != null:
		my_peer.close()
	
	var multi_node := WebRTCMultiplayer.new()
	my_peer = WebRTCPeerConnection.new()
	
	var err := multi_node.add_peer(my_peer, 1)
	if err != OK:
		push_error("Unable to add my RTC peer: %s" % err)
		return false
	
	err = multi_node.initialize(1, true)
	if err != OK:
		push_error("Unable to initialize my RTC peer: %s" % err)
		return false
	
	my_peer.connect("session_description_created", self, "_on_answer_created")
	my_peer.connect("ice_candidate_created", self, "_on_ice_candidate_created")
	err = my_peer.set_remote_description("offer", sdp)
	if err != OK:
		push_error("Unable to create rtc answer: %s" % err)
		return false
	
	var res = yield(self, "_rtc_attempt_finished")
	if res == null:
		return false
	res = MangleApi.join_session_followup(res[0], res[1])
	if res == null:
		return false
	err = my_peer.add_ice_candidate(res["media"], res["index"], res["name"])
	if err != OK:
		push_error("Unable to add ice candidate: %s" % err)
		return false
	
	return true


func _on_answer_created(type: String, sdp: String):
	assert(type == "answer")
	var err := my_peer.set_local_description(type, sdp)
	if err != OK:
		push_error("Unable to set local description: %s" % err)
		emit_signal("_rtc_attempt_finished", null)
		return
	
	emit_signal("_rtc_attempt_finished", [sdp, yield(self, "_ice_created")])


func _on_ice_candidate_created(media: String, index: int, ice_name: String):
	emit_signal("_ice_created", "{\"media\": \"%s\", \"index\": %s, \"name\": \"%s\"}" % [media, index, ice_name])
