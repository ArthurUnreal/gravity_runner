extends CanvasLayer

@onready var score_label: Label = $VBox/ScoreLabel
@onready var best_label: Label = $VBox/BestLabel
@onready var start_screen: Control = $StartScreen
@onready var game_over_screen: Control = $GameOverScreen
@onready var game_over_score: Label = $GameOverScreen/VBox/ScoreValue
@onready var game_over_best: Label = $GameOverScreen/VBox/BestValue
@onready var diff_bar: ProgressBar = $VBox/DifficultyBar

var best_score: int = 0

signal start_requested
signal restart_requested

func _ready() -> void:
	load_best()
	show_start()
	
	start_screen.get_node("VBox/StartButton").pressed.connect(_on_start)
	start_screen.get_node("VBox/QuitButton").pressed.connect(_on_quit)
	game_over_screen.get_node("VBox/RetryButton").pressed.connect(_on_retry)
	game_over_screen.get_node("VBox/MenuButton").pressed.connect(_on_menu)

func _process(delta: float) -> void:
	pass

func update_score(score: int) -> void:
	score_label.text = "SCORE: %d" % score
	if score > best_score:
		best_score = score
		best_label.text = "BEST: %d" % best_score
		save_best()

func update_difficulty(d: float) -> void:
	diff_bar.value = (d - 1.0) / 2.0 * 100.0

func show_start() -> void:
	start_screen.visible = true
	game_over_screen.visible = false

func show_playing() -> void:
	start_screen.visible = false
	game_over_screen.visible = false

func show_game_over(score: int) -> void:
	game_over_score.text = "%d" % score
	game_over_best.text = "%d" % best_score
	game_over_screen.visible = true

func _on_start() -> void:
	start_requested.emit()

func _on_retry() -> void:
	restart_requested.emit()

func _on_menu() -> void:
	show_start()

func _on_quit() -> void:
	get_tree().quit()

func save_best() -> void:
	var f = FileAccess.open("user://best.save", FileAccess.WRITE)
	if f:
		f.store_32(best_score)
		f.close()

func load_best() -> void:
	var f = FileAccess.open("user://best.save", FileAccess.READ)
	if f:
		best_score = f.get_32()
		best_label.text = "BEST: %d" % best_score
		f.close()
