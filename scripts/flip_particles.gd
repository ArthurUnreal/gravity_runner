## 翻转粒子发射器 - 在翻转时产生粒子爆发
extends GPUParticles2D

func _ready() -> void:
	one_shot = true
	emitting = false

func burst(pos: Vector2, dir: int) -> void:
	global_position = pos
	# 根据翻转方向调整粒子发射
	process_material.direction = Vector3(0, -dir, 0)
	process_material.spread = 120.0
	emitting = true
	# 等待一次爆发后自动停止
	await get_tree().create_timer(0.6).timeout
	emitting = false
