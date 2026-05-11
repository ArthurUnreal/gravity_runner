shader_type canvas_item;

// 翻转特效：快速扩散的光圈
uniform float progress : hint_range(0.0, 1.0) = 0.0;  // 0→1 扩散
uniform float max_radius : hint_range(0.0, 3.0) = 1.8;
uniform vec4 ring_color : source_color = vec4(0.91, 0.27, 0.38, 1.0);
uniform float ring_thickness : hint_range(0.01, 0.5) = 0.2;

void fragment() {
    // 基于 sprite 的实际尺寸计算圆形
    // VERTEX 是局部坐标，范围是 [-size/2, size/2]
    // 标准化到 [-1, 1]
    vec2 uv = (VERTEX) / (TEXTURE_PIXEL_SIZE * vec2(texture_size(TEXTURE, 0)));
    uv = clamp(uv, vec2(-1.0), vec2(1.0));
    
    float dist = length(uv);
    
    float radius = progress * max_radius;
    
    // 环形
    float ring = smoothstep(radius - ring_thickness, radius, dist) 
              * smoothstep(radius + ring_thickness * 0.5, radius, dist);
    
    // 从中心到边缘自然淡出
    ring *= smoothstep(max_radius + ring_thickness, max_radius * 0.5, dist);
    
    // 透明度随扩散递减
    float alpha = ring * (1.0 - progress) * 0.9;
    
    COLOR = ring_color;
    COLOR.a = alpha;
}
