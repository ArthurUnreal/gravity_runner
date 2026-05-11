extends CharacterBody2D
## 玩家控制器 - 重力翻转核心手感
## 参数设计思路：即时反馈 + 重量感 + 公平感
##
## 三大原则：
## 1. 翻转：力量感 - 翻转不是"飘过去"，是"弹过去"
## 2. 落地：冲击感 - 每一脚落地都值得被记住
## 3. 容错：Coyote Time - 玩家"感觉自己能跳"比实际上能跳更重要

signal died

# ─────────────────────────────────────────
# 基础物理参数
# ─────────────────────────────────────────

const MOVE_SPEED: float = 200.0  # 恒定速度，操作预期稳定

# 重力由 game_manager 动态控制（750-950）
# 翻转初速需要比重力能产生的最大下落速度快，给"蹬地"感
const JUMP_VELOCITY: float = -460.0  # 比最大重力加速度(950*dt≈25/帧)大很多

# ─────────────────────────────────────────
# 翻转手感（最关键参数）
# ─────────────────────────────────────────
#
# 翻转设计原则：
# - 翻转瞬间给一个明确的向上初速，让你感觉"蹬"了一下
# - cooldown 150ms 足够短可以连翻，不至于长到卡手感
# - 但也不是 0，所以不能无脑乱按，需要节奏

const FLIP_COOLDOWN: float = 0.15  # 稳定不变，玩家形成肌肉记忆

# ─────────────────────────────────────────
# Coyote Time（公平感的关键）
# ─────────────────────────────────────────
#
# 体验原理：玩家判断"我能不能跳"是在脚离开平台之前
# 如果落地后 80-120ms 内还能跳，玩家会觉得"本来就能跳"
# 如果落地后立刻跳不了，玩家会觉得"这游戏有问题"
# 实际测试：100ms 是甜蜜点，够短不影响难度，够长消除误判

const COYOTE_TIME: float = 0.10  # 100ms

# ─────────────────────────────────────────
# Squash & Stretch（落地冲击感）
# ─────────────────────────────────────────
#
# 参数设计：
# - squash_x = 1.35：落地时横向撑开35%，增加"脚感"
# - squash_y = 0.65：纵向压扁35%，强化冲击
# - squash 恢复速度：100ms 内回到正常，有轻微回弹
# - 回弹overshoot不重要，落地那一下的 squash 是核心

const LAND_SQUASH_X: float = 1.35
const LAND_SQUASH_Y: float = 0.65
const SQUASH_RECOVER_TIME: float = 0.10  # 秒
const SQUASH_RECOVER_SPRING: float = 22.0  # spring 系数，越大回弹越快

# ─────────────────────────────────────────
# 屏幕震动（反馈感）
# ─────────────────────────────────────────
#
# 参数设计原则：
# - 落地震动：短促（60ms），轻微（2px），强化落地但不抢注意力
# - 翻转震动：极短（40ms），极轻（1.5px），提示翻转已触发
# - 死亡震动：较长（250ms），较强（6px），戏剧感
# - 所有震动都是"点缀"，不是"干扰"

const LAND_SHAKE_DUR: float = 0.06
const LAND_SHAKE_STR: float = 2.0
const FLIP_SHAKE_DUR: float = 0.04
const FLIP_SHAKE_STR: float = 1.5
const DEATH_SHAKE_DUR: float = 0.25
const DEATH_SHAKE_STR: float = 6.0

# ─────────────────────────────────────────
# Trail（拖尾）
# ─────────────────────────────────────────
#
# 拖尾让高速运动可见，帮助玩家预判位置
# 8-12 段刚好够用，不吃性能

const TRAIL_MAX: int = 10

# ─────────────────────────────────────────
# 节点引用
# ─────────────────────────────────────────

@onready var sprite: Sprite2D = $Sprite2D
@onready var player_shader: Sprite2D = $PlayerShader
@onready var trail: Line2D = $Trail
@onready var flip_ring: Sprite2D = $FlipRing
@onready var squash_timer: Timer = $SquashTimer
@onready var flip_anim_timer: Timer = $FlipAnimTimer
@onready var flip_particles: GPUParticles2D = $FlipParticles
@onready var screen_shake: Node = $"../ScreenShake"
@onready var game_manager: Node = $"../GameManager"

var gravity_direction: int = 1  # 1=向下, -1=向上
var gravity: float = 750.0
var is_dead: bool = false
var can_flip: bool = true
var was_on_ground: bool = false
var coyote_timer: float = 0.0
var flip_cooldown_timer: float = 0.0

# Squash state
var squash_scale: Vector2 = Vector2(1.0, 1.0)

# Trail
var trail_points: Array[Vector2] = []

func _ready() -> void:
	add_to_group("player")
	_update_shader_flip()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Flip cooldown
	if not can_flip:
		flip_cooldown_timer -= delta
		if flip_cooldown_timer <= 0:
			can_flip = true
	
	# Coyote Time 计时
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta
	
	# 动态重力（由 game_manager 控制）
	gravity = game_manager.get_player_gravity() if game_manager else 750.0
	velocity.y += gravity * gravity_direction * delta
	
	# 水平速度恒定
	velocity.x = game_manager.get_player_speed() if game_manager else MOVE_SPEED
	
	# Squash 应用
	_apply_squash(delta)
	
	# 移动
	move_and_slide()
	
	# 落地检测
	var on_ground_now := is_on_floor()
	if on_ground_now and not was_on_ground:
		_on_land()
	was_on_ground = on_ground_now
	
	# 出界检测（上下都算死）
	if global_position.y > 1100 or global_position.y < -300:
		die()
	
	# Trail 更新
	trail_points.push_front(global_position)
	if trail_points.size() > TRAIL_MAX:
		trail_points.pop_back()
	trail.points = trail_points

func _input(event: InputEvent) -> void:
	if is_dead:
		return
	if event.is_action_pressed("flip") and can_flip:
		flip_gravity()

func flip_gravity() -> void:
	gravity_direction *= -1
	can_flip = false
	flip_cooldown_timer = game_manager.get_flip_cooldown() if game_manager else FLIP_COOLDOWN
	
	# 翻转给明确的蹬地初速
	velocity.y = JUMP_VELOCITY * gravity_direction
	
	# Shader 翻转
	_update_shader_flip()
	
	# 翻转光环 + 粒子
	_play_flip_ring()
	if flip_particles:
		flip_particles.burst(global_position, gravity_direction)
	
	# 翻转震动（极轻极短，只是提示）
	if screen_shake:
		screen_shake.shake(FLIP_SHAKE_DUR, FLIP_SHAKE_STR)

func _update_shader_flip() -> void:
	if player_shader and player_shader.material:
		player_shader.material.set_shader_parameter("flip_scale_y", float(gravity_direction))

func _play_flip_ring() -> void:
	flip_ring.visible = true
	flip_ring.global_position = global_position
	if flip_ring.material:
		flip_ring.material.set_shader_parameter("progress", 0.0)
	
	var tween = create_tween()
	tween.tween_property(flip_ring.material, "shader_parameter/progress", 1.0, 0.22)
	tween.tween_callback(func(): flip_ring.visible = false)

func _on_land() -> void:
	# 落地 squash
	squash_scale = Vector2(LAND_SQUASH_X, LAND_SQUASH_Y)
	squash_timer.start(SQUASH_RECOVER_TIME)
	
	# 落地震动
	if screen_shake:
		screen_shake.shake(LAND_SHAKE_DUR, LAND_SHAKE_STR)

func _apply_squash(delta: float) -> void:
	# Spring 恢复，有轻微回弹
	squash_scale = squash_scale.lerp(Vector2(1.0, 1.0), delta * SQUASH_RECOVER_SPRING)
	
	if player_shader:
		var final_scale = squash_scale * Vector2(1.0, abs(gravity_direction))
		player_shader.scale = final_scale

func die() -> void:
	if is_dead:
		return
	is_dead = true
	
	if screen_shake:
		screen_shake.big_shake(DEATH_SHAKE_DUR, DEATH_SHAKE_STR)
	
	died.emit()
