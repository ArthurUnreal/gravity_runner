extends Node2D
## 屏幕震动效果

var intensity: float = 0.0
var duration: float = 0.0
var timer: float = 0.0
var base_offset: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if duration > 0:
		timer -= delta
		if timer <= 0:
			duration = 0
			base_offset = Vector2.ZERO
		else:
			var shake = Vector2(
				randf_range(-intensity, intensity),
				randf_range(-intensity, intensity)
			)
			base_offset = shake

func shake(dur: float, str: float) -> void:
	duration = dur
	timer = dur
	intensity = str

func big_shake(dur: float, str: float) -> void:
	duration = dur
	timer = dur
	intensity = str
	# Flash red (通过调色实现)
	var bg = get_node_or_null("/root/Main/Background")
	if bg:
		bg.modulate = Color(1.0, 0.5, 0.5, 1.0)
		await get_tree().create_timer(0.15).timeout
		if bg:
			bg.modulate = Color.WHITE

func pulse(dur: float, str: float) -> void:
	# 快速 zoom pulse via camera
	var cam = get_viewport().get_camera_2d()
	if cam:
		var orig_zoom = cam.zoom
		cam.zoom = Vector2(1.0 + str * 0.05, 1.0 + str * 0.05)
		await get_tree().create_timer(dur).timeout
		if cam:
			cam.zoom = orig_zoom
