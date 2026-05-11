extends Node2D
## 平台生成器 - 保证可解的无尽关卡生成

@onready var platform_scene: PackedScene = preload("res://scenes/platform.tscn")
@onready var game_manager: Node = $"../GameManager"

var last_platform_y: float = 500.0
var last_platform_right_x: float = 200.0
var platforms: Array[Node2D] = []
var camera_x: float = 0.0

const SCREEN_W: float = 540.0
const SCREEN_H: float = 960.0
const CAMERA_AHEAD: float = 600.0  # 提前生成的距离

func _ready() -> void:
	# 从底部开始，生成初始平台
	spawn_start_platforms()

func _process(delta: float) -> void:
	if not game_manager.is_playing:
		return
	
	# 根据玩家位置调整生成基准（玩家固定在屏幕左侧）
	# 生成器跟随玩家向上扩展

func spawn_start_platforms() -> void:
	# 初始落脚平台
	var start_platform = _create_platform(200, 0, SCREEN_H - 100, false, false)
	# 生成第一批平台
	for i in range(8):
		_generate_next_platform()

func _generate_next_platform() -> void:
	var difficulty: float = game_manager.current_difficulty if game_manager else 1.0
	var width: float = game_manager.get_platform_width() if game_manager else 100.0
	var gap: float = game_manager.get_platform_gap() if game_manager else 100.0
	var hazard_prob: float = game_manager.get_hazard_probability() if game_manager else 0.0
	var moving_prob: float = game_manager.get_moving_platform_probability() if game_manager else 0.0
	
	# 计算新平台位置
	var new_y: float = last_platform_y - gap
	var x_range: float = SCREEN_W - width
	
	# 确保可达性：x方向最大跳跃距离约 200px（按住右方向）
	var max_jump_dx: float = 200.0
	var min_x: float = max(0, last_platform_right_x - max_jump_dx)
	var max_x: float = min(SCREEN_W - width, last_platform_right_x + max_jump_dx * 0.5)
	
	var new_x: float = randf_range(min_x, max_x)
	last_platform_right_x = new_x + width
	
	# 随机类型
	var is_moving: bool = randf() < moving_prob
	var is_hazard: bool = not is_moving and randf() < hazard_prob
	
	_create_platform(width, new_x, new_y, is_hazard, is_moving)
	
	last_platform_y = new_y

func _create_platform(w: float, x: float, y: float, hazard: bool, moving: bool) -> Node2D:
	var p: Node2D = platform_scene.instantiate()
	p.global_position = Vector2(x + w / 2.0, y)
	p.setup(w, 0, moving)
	add_child(p)
	platforms.append(p)
	return p

func _on_cull_old_platforms(camera_x: float) -> void:
	for p in platforms:
		if p.global_position.x < camera_x - 300:
			p.queue_free()
			platforms.erase(p)

func generate_while_playing(player_y: float) -> void:
	# 当玩家接近生成前沿时，继续生成
	var threshold: float = last_platform_y + SCREEN_H * 0.8
	while last_platform_y > player_y - SCREEN_H:
		_generate_next_platform()

func reset() -> void:
	# 清理所有平台
	for p in platforms:
		if is_instance_valid(p):
			p.queue_free()
	platforms.clear()
	last_platform_y = 500.0
	last_platform_right_x = 200.0
	spawn_start_platforms()
