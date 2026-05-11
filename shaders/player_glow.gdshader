shader_type canvas_item;

// 玩家发光圆形 shader
uniform vec4 base_color : source_color = vec4(0.91, 0.27, 0.38, 1.0);  // #e94560
uniform vec4 glow_color : source_color = vec4(0.91, 0.27, 0.38, 0.0);
uniform float glow_radius : hint_range(0.0, 2.0) = 0.55;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.5;
uniform float inner_radius : hint_range(0.0, 1.0) = 0.28;

// 上下翻转时的y轴缩放 (from player.gd gravity_direction)
uniform float flip_scale_y : hint_range(-1.0, 1.0) = 1.0;

void fragment() {
    // 用 VERTEX 坐标，不依赖贴图分辨率
    vec2 uv = (VERTEX) / (TEXTURE_PIXEL_SIZE * vec2(texture_size(TEXTURE, 0)));
    // 或者更简单：用 UV 直接，从中心标准化
    uv = UV;
    
    // 标准化到中心
    vec2 centered = (UV - vec2(0.5)) * 2.0;
    
    // 应用翻转缩放
    centered.y /= flip_scale_y;
    
    float dist = length(centered);
    
    // 脉冲呼吸效果
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
    
    // 外发光
    float glow = smoothstep(glow_radius + pulse * 0.1, glow_radius - 0.2, dist);
    
    // 内部实心圆
    float core = smoothstep(inner_radius, inner_radius - 0.05, dist);
    
    // 边缘高光
    float rim = smoothstep(inner_radius + 0.08, inner_radius + 0.02, dist) 
              * smoothstep(inner_radius - 0.02, inner_radius + 0.08, dist);
    
    // 组装颜色
    vec4 final_color = base_color;
    
    // 叠加外发光
    final_color = mix(final_color, glow_color, glow * (0.4 + pulse * 0.3));
    
    // 白色高光 rim
    final_color.rgb = mix(final_color.rgb, vec3(1.0), rim * 0.4);
    
    // 核心更亮
    final_color.rgb += (core - dist * 0.5) * 0.2;
    
    // alpha: 实心圆 + 发光边缘
    float alpha = max(core, glow * 0.6);
    
    COLOR = final_color;
    COLOR.a = alpha;
}
