@tool 
extends Node
signal star_collected
signal lives_changed
signal game_ended(ending: Endings)
signal game_started
signal gravity_changed(gravity: float)
signal timer_added

enum Endings { WIN, LOSE}
enum Player { ONE }
enum PhysicsLayers {
	PLAYER = 1,
	STARS = 2, 
	PLATFORMS = 3, 
	ENEMY = 4,
}

var timer: Timer
var stars: int = 0
var lives: int = 3:
	set = _set_lives

func collect_star():
	stars += 1
	star_collected.emit()

func setup_timer(time_limit: int):
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start(time_limit)
	timer.paused = true
	timer_added.emit()

func _on_timer_timeout():
	game_ended.emit(Endings.LOSE)

func _set_lives(value):
	if value  < 0:
		return
	lives = value
	lives_changed.emit()
	if lives <= 0:
		game_ended.emit(Endings.LOSE)

func _ready():
	game_ended.connect(_on_game_ended)
	game_started.connect(_on_game_start)

func _on_game_ended(_endings: Endings):
	if timer and not timer.is_stopped():
		timer.paused = true

func _on_game_start():
	if timer != null:
		timer.paused = false
