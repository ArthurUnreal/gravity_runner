extends Node2D
## 平台生成器 - 保证可解的无尽关卡生成

@onready var platform_scene: PackedScene = preload("res://scenes/platform.tscn")
@onready var game_manager: Node = $"../GameManager"

var last_platform_y: float = 500.0
var last_platform_right_x: float = 200.0
var platforms: Array[Node2D] = []

const SCREEN_W: float = 540.0
const SCREEN_H: float = 960.0
const GENERATE_AHEAD: float = 400.0  # 在玩家上方多远开始生成

func _ready() -> void:
	spawn_start_platforms()

func _process(delta: float) -> void:
	if not game_manager.is_playing:
		return
	
	# 获取玩家位置（相对于世界坐标）
	var player = get_node_or_null("../Player") as Node2D
	if not player:
		return
	
	var player_y = player.global_position.y
	
	# 当玩家接近生成前沿时，继续生成
	while last_platform_y > player_y - SCREEN_H - GENERATE_AHEAD:
		_generate_next_platform()
	
	# 清理已过时的平台
	_cull_old_platforms(player.global_position.x)

func spawn_start_platforms() -> void:
	# 清理旧平台
	for p in platforms:
		if is_instance_valid(p):
			p.queue_free()
	platforms.clear()
	
	# 重置生成状态
	last_platform_y = SCREEN_H - 80.0  # 从底部开始
	last_platform_right_x = 100.0
	
	# 初始落脚平台（宽一点，让玩家容易站）
	_create_platform(200, 20, SCREEN_H - 80, false, false)
	
	# 生成第一批平台（预生成到屏幕上方）
	for i in range(15):
		_generate_next_platform()

func _generate_next_platform() -> void:
	var difficulty: float = game_manager.current_difficulty if game_manager else 1.0
	var width: float = game_manager.get_platform_width() if game_manager else 130.0
	var gap: float = game_manager.get_platform_gap() if game_manager else 90.0
	var hazard_prob: float = game_manager.get_hazard_probability() if game_manager else 0.0
	var moving_prob: float = game_manager.get_moving_platform_probability() if game_manager else 0.0
	
	# 计算新平台Y位置（向上增长）
	var new_y: float = last_platform_y - gap
	
	# X范围：确保可达（x方向最大跳跃距离约 180px）
	var max_jump_dx: float = 180.0
	var min_x: float = max(0, last_platform_right_x - max_jump_dx)
	var max_x: float = min(SCREEN_W - width, last_platform_right_x + max_jump_dx * 0.3)
	
	# 如果范围异常，随机生成
	var new_x: float
	if max_x > min_x:
		new_x = randf_range(min_x, max_x)
	else:
		new_x = randf_range(20.0, SCREEN_W - width - 20.0)
	
	last_platform_right_x = new_x + width / 2.0
	
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

func _cull_old_platforms(player_x: float) -> void:
	# 清理屏幕左侧外侧的平台
	for p in platforms:
		if not is_instance_valid(p):
			continue
		# 平台完全在玩家左侧超过300像素时删除
		if p.global_position.x + 100 < player_x - SCREEN_W:
			p.queue_free()
	
	# 清理失效引用
	platforms = platforms.filter(func(p): return is_instance_valid(p))

func reset() -> void:
	spawn_start_platforms()
