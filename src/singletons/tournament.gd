extends Node


signal initialized

const WINS_NEEDED := 10

var initialized := false
var week_number: int
var tournament_seed: int
var since: int
var until: int
var time_until: int

var enabled := false

var _win_count := 0


func get_won_tournament() -> bool:
	return week_number in MangleApi.account_data.tournament_wins


# warning-ignore-all:shadowed_variable
func initialize(week_number: int, tournament_seed: int, since: int, until: int):
	self.week_number = week_number
	self.tournament_seed = tournament_seed
	self.since = since
	self.until = until
	initialized = true
	# warning-ignore:return_value_discarded
	get_tree().create_timer(until - since).connect("timeout", MangleApi, "init_tournament")
	emit_signal("initialized")


func get_time_until() -> int:
	return until - OS.get_system_time_secs()


func win_level():
	_win_count += 1
	
	if get_won_tournament():
		return
	
	if _win_count >= WINS_NEEDED:
		yield(MangleApi.win_tournament(week_number), "completed")


func reset():
	_win_count = 0
