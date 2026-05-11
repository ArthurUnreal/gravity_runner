extends StaticBody2D
## 平台 - 支持普通/移动/危险平台 + Shader联动

enum Type { NORMAL, MOVING, HAZARD }

@export var platform_type: Type = Type.NORMAL
@export var move_distance: float = 60.0
@export var move_speed: float = 80.0

var base_pos: Vector2
var move_dir: float = 1.0
var half_width: float = 60.0
var _setup_done: bool = false

func _ready() -> void:
	# 不在这里做任何假设，等 setup() 被调用时节点一定 ready 了
	pass

func _process(delta: float) -> void:
	if platform_type == Type.MOVING:
		global_position.x += move_dir * move_speed * delta
		if abs(global_position.x - base_pos.x) > move_distance:
			move_dir *= -1.0
	
	# Remove when off-screen left
	if global_position.x < -200:
		queue_free()

func setup(width: float, type: Type = Type.NORMAL, is_moving: bool = false) -> void:
	if _setup_done:
		return
	_setup_done = true
	
	half_width = width / 2.0
	platform_type = type
	base_pos = global_position
	
	# 调整碰撞体 - 用 find_child 确保拿到子节点
	var collision_node = find_child("CollisionShape2D", true, false) as CollisionShape2D
	if collision_node and collision_node.shape:
		var rect_shape = collision_node.shape as RectangleShape2D
		rect_shape.size = Vector2(width, 12)
	
	# 调整 shader sprite 大小
	var shader_sprite = find_child("PlatformShader", true, false) as Sprite2D
	if shader_sprite:
		shader_sprite.scale = Vector2(width, 12)
	
	# 更新 shader 参数
	if shader_sprite and shader_sprite.material:
		var mat = shader_sprite.material
		if is_moving:
			platform_type = Type.MOVING
			mat.set_shader_parameter("is_hazard", false)
			mat.set_shader_parameter("is_moving", true)
		elif type == Type.HAZARD:
			platform_type = Type.HAZARD
			mat.set_shader_parameter("is_hazard", true)
			mat.set_shader_parameter("is_moving", false)
		else:
			mat.set_shader_parameter("is_hazard", false)
			mat.set_shader_parameter("is_moving", false)
