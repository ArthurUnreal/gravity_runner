shader_type canvas_item;

// 拖尾粒子 shader - 渐隐效果
uniform float trail_length : hint_range(0.0, 1.0) = 0.8;
uniform vec4 trail_color : source_color = vec4(0.91, 0.27, 0.38, 0.5);
uniform float fade_power : hint_range(1.0, 5.0) = 2.5;

void fragment() {
    float alpha = trail_color.a;
    // UV.y 表示从起点到终点的位置，1=起点（最新）, 0=终点（最老）
    float position = UV.y;
    
    // 从起点到终点渐隐
    alpha *= pow(position, fade_power);
    
    // 两端自然淡出
    float edge_fade = smoothstep(0.0, 0.15, position) 
                    * smoothstep(trail_length, trail_length - 0.15, position);
    alpha *= edge_fade;
    
    COLOR = trail_color;
    COLOR.a *= alpha;
}
