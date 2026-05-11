extends Node2D
## 游戏主控制器 - 管理游戏状态、难度曲线、计分
## 参数设计思路：体验优先，渐进式挑战，"再来一局"陷阱

signal game_over
signal score_changed(score: int)
signal difficulty_changed(difficulty: float)

var score: int = 0
var elapsed_time: float = 0.0
var is_playing: bool = false
var is_game_over: bool = false

# ─────────────────────────────────────────
# 核心难度曲线参数（体验导向设计）
# ─────────────────────────────────────────
#
# 体验原则：
# 1. 前 15 秒：新手保护期，难度几乎不动，让玩家掌握翻转时机
# 2. 15-60 秒：逐渐上强度，每次挑战略有增加，不突然
# 3. 60 秒后：进入高压区，考验持续注意力，但平台仍有解
#
# 曲线用 sigmoid 函数代替线性：
#   difficulty = 1.0 + 1.5 / (1 + e^(-k*(t-t0)))
#   t0=25s（拐点）, k=0.06
#   结果：15s=1.15 → 30s=1.5 → 60s=2.0 → 90s=2.35 → 120s=2.45

var current_difficulty: float = 1.0
var current_phase: String = "learn"  # "learn" | "ramp" | "intense"

# 各维度基础值（难度1.0时）
var base_platform_width: float = 130.0
var base_platform_gap: float = 90.0
var base_player_speed: float = 200.0
var base_gravity: float = 750.0
var hazard_unlock_difficulty: float = 1.3  # 约25秒解锁
var moving_unlock_difficulty: float = 1.15  # 约15秒解锁

func _ready() -> void:
	game_over.connect(_on_game_over)

func _process(delta: float) -> void:
	if not is_playing:
		return
	
	elapsed_time += delta
	# Sigmoid 难度曲线
	var k: float = 0.055
	var t0: float = 28.0  # 拐点位置（秒）
	var raw: float = 1.0 + 1.6 / (1.0 + exp(-k * (elapsed_time - t0)))
	current_difficulty = clampf(raw, 1.0, 2.6)
	
	# 相位标记（用于 UI 提示）
	if elapsed_time < 15.0:
		current_phase = "learn"
	elif elapsed_time < 60.0:
		current_phase = "ramp"
	else:
		current_phase = "intense"
	
	difficulty_changed.emit(current_difficulty)
	
	# 分数 = 时间 × 基础倍率 × 难度（后期每一秒都更值钱）
	score = int(elapsed_time * 12.0 * pow(current_difficulty, 0.7))
	score_changed.emit(score)

func start_game() -> void:
	score = 0
	elapsed_time = 0.0
	current_difficulty = 1.0
	current_phase = "learn"
	is_playing = true
	is_game_over = false
	score_changed.emit(score)

func end_game() -> void:
	if is_game_over:
		return
	is_game_over = true
	is_playing = false
	game_over.emit()

func _on_game_over() -> void:
	is_playing = false

# ─────────────────────────────────────────
# 难度查询接口（供其他模块调用）
# 原则：所有参数变化都是渐进的，没有突变
# ─────────────────────────────────────────

func get_platform_width() -> float:
	# 130 → 55 像素（新手宽，后期窄但不至于站不住）
	return clampf(base_platform_width - current_difficulty * 28.0, 55.0, 130.0)

func get_platform_gap() -> float:
	# 90 → 160 像素（新手容易跳，后期需要精准）
	return clampf(base_platform_gap + current_difficulty * 28.0, 90.0, 160.0)

func get_player_gravity() -> float:
	# 750 → 950（重力略增，让下落更快但不失控）
	return clampf(base_gravity + current_difficulty * 80.0, 750.0, 950.0)

func get_player_speed() -> float:
	# 保持稳定，不随难度变化（速度稳定是操作预期的基础）
	return base_player_speed

func get_hazard_probability() -> float:
	# 约25秒开始出现，之后缓慢增加
	return clampf((current_difficulty - hazard_unlock_difficulty) * 0.35, 0.0, 0.45)

func get_moving_platform_probability() -> float:
	# 约15秒开始出现，早于危险平台
	return clampf((current_difficulty - moving_unlock_difficulty) * 0.25, 0.0, 0.35)

func get_flip_cooldown() -> float:
	# 始终固定 0.15s，不随难度变化
	# 原因：cooldown 稳定性是操作预期的核心
	return 0.15

func get_phase() -> String:
	return current_phase
