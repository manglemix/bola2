extends Node


signal _rtc_attempt_finished(code)

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
	var err := my_peer.set_local_description(type, sdp)
	if err != OK:
		push_error("Unable to set local description: %s" % err)
		emit_signal("_rtc_attempt_finished", null)
		return
	
	var code = yield(MangleApi.send_host_session_request(sdp), "completed")
	if code == null:
		push_error("Host Session Request failed")
		emit_signal("_rtc_attempt_finished", null)
		return
	
	emit_signal("_rtc_attempt_finished", code)


func join_session(code: String):
	var sdp = yield(MangleApi.send_join_session_request(code), "completed")
	if sdp == null:
		push_error("Join Session Request failed")
		return
	if sdp == "":
		return
	
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
	
	my_peer.connect("session_description_created", self, "_on_answer_created")
	err = my_peer.set_remote_description("offer", sdp)
	if err != OK:
		push_error("Unable to create rtc answer: %s" % err)
		return


func _on_answer_created(type: String, sdp: String):
	var err := my_peer.set_local_description(type, sdp)
	if err != OK:
		push_error("Unable to set local description: %s" % err)
		emit_signal("_rtc_attempt_finished", null)
		return
	
	var code = yield(MangleApi.send_host_session_request(sdp), "completed")
	if code == null:
		push_error("Host Session Request failed")
		emit_signal("_rtc_attempt_finished", null)
		return
	
	emit_signal("_rtc_attempt_finished", code)
