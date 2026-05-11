shader_type canvas_item;

// 翻转特效：快速扩散的光圈
// 用 VERTEX 本地像素坐标，不依赖 texture

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float max_radius : hint_range(0.0, 100.0) = 30.0;  // 最大扩散半径（像素）
uniform float ring_thickness : hint_range(0.0, 50.0) = 6.0;  // 环宽度（像素）

void fragment() {
    // VERTEX 是 sprite 局部像素坐标
    float dist = length(VERTEX);
    
    float radius = progress * max_radius;
    
    // 环形
    float ring = smoothstep(radius - ring_thickness, radius, dist) 
              * smoothstep(radius + ring_thickness * 0.3, radius, dist);
    
    // 从中心到边缘自然淡出
    ring *= smoothstep(max_radius + ring_thickness, max_radius * 0.5, dist);
    
    // 透明度随扩散递减
    float alpha = ring * (1.0 - progress) * 0.9;
    
    // 玫红色
    COLOR = vec4(0.91, 0.27, 0.38, alpha);
}
