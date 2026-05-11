shader_type canvas_item;

// 翻转特效：快速扩散的光圈
uniform float progress : hint_range(0.0, 1.0) = 0.0;  // 0→1 扩散
uniform float max_radius : hint_range(0.0, 3.0) = 1.5;
uniform vec4 ring_color : source_color = vec4(0.91, 0.27, 0.38, 1.0);
uniform float ring_thickness : hint_range(0.01, 0.5) = 0.15;

void fragment() {
    vec2 uv = (UV - vec2(0.5)) / vec2(0.5);
    float dist = length(uv);
    
    float radius = progress * max_radius;
    float ring = smoothstep(radius - ring_thickness, radius, dist) 
              * smoothstep(radius + ring_thickness * 0.5, radius, dist);
    
    // 边缘淡出
    ring *= smoothstep(max_radius + ring_thickness, max_radius * 0.5, dist);
    
    // 透明度随扩散递减
    float alpha = ring * (1.0 - progress) * 0.8;
    
    COLOR = ring_color;
    COLOR.a = alpha;
}
