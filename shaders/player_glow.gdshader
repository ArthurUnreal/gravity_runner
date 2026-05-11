shader_type canvas_item;

// 玩家发光圆形 - 用 VERTEX 本地坐标画圆，不依赖 texture UV

uniform vec4 base_color : source_color = vec4(0.91, 0.27, 0.38, 1.0);
uniform float glow_radius : hint_range(0.0, 100.0) = 20.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.5;
uniform float inner_radius : hint_range(0.0, 100.0) = 8.0;
uniform float flip_scale_y : hint_range(-1.0, 1.0) = 1.0;

void fragment() {
    // VERTEX 是 sprite 局部坐标，直接以像素为单位
    // sprite scale=48，实际大小就是 48x48 像素
    // 中心是 (0,0)
    vec2 centered = VERTEX;
    centered.y /= flip_scale_y;
    
    float dist = length(centered);
    
    // 脉冲呼吸
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
    
    // 核心实心圆
    float core = smoothstep(inner_radius, inner_radius - 1.0, dist);
    
    // 外发光
    float glow = smoothstep(glow_radius + pulse * 2.0, glow_radius, dist);
    
    // 边缘高光
    float rim = smoothstep(inner_radius + 2.0, inner_radius, dist) 
              * smoothstep(inner_radius - 1.0, inner_radius, dist);
    
    // 混合颜色
    vec4 col = base_color;
    col.rgb = mix(col.rgb, vec3(1.0), rim * 0.5);  // 边缘高光
    col.a = max(core, glow * 0.5);
    
    COLOR = col;
}
