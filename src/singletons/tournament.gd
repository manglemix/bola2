extends Node


const WINS_NEEDED := 10

var initialized := false
var week_number: int
var tournament_seed: int
var since: int
var until: int
var time_until: int

var enabled := false
var won_tournament := false

var _win_count := 0


# warning-ignore-all:shadowed_variable
func initialize(week_number: int, tournament_seed: int, since: int, until: int):
	self.week_number = week_number
	self.tournament_seed = tournament_seed
	self.since = since
	self.until = until
	initialized = true


func get_time_until() -> int:
	return until - OS.get_system_time_secs()


func win_level():
	_win_count += 1
	
	if won_tournament:
		return
	
	if _win_count >= WINS_NEEDED:
		MangleApi.win_tournament(week_number)
		won_tournament = true


func reset():
	_win_count = 0
