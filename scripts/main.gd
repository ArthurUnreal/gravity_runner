extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var game_manager: Node = $GameManager
@onready var generator: Node = $PlatformGenerator
@onready var screen_shake: Node = $ScreenShake
@onready var ui: CanvasLayer = $UI
@onready var bg: ColorRect = $Background

var player_scene: PackedScene = preload("res://scenes/player.tscn")

func _ready() -> void:
	ui.start_requested.connect(_on_start)
	ui.restart_requested.connect(_on_restart)
	player.died.connect(_on_player_died)
	game_manager.score_changed.connect(ui.update_score)
	game_manager.difficulty_changed.connect(ui.update_difficulty)
	
	# 背景色初始化
	bg.color = Color(0.1, 0.1, 0.15, 1.0)

func _on_start() -> void:
	_restart_game()
	game_manager.start_game()
	ui.show_playing()
	generator.reset()

func _on_restart() -> void:
	_restart_game()
	game_manager.start_game()
	ui.show_playing()
	generator.reset()

func _restart_game() -> void:
	# Reset player position
	player.global_position = Vector2(100, SCREEN_H - 200)
	player.gravity_direction = 1
	player.velocity = Vector2(200, 0)
	player.is_dead = false
	player.squash_scale = Vector2(1.0, 1.0)

func _on_player_died() -> void:
	game_manager.end_game()
	ui.show_game_over(game_manager.score)

const SCREEN_H: float = 960.0
