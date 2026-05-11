shader_type canvas_item;

// 平台发光边框 shader
uniform vec4 platform_color : source_color = vec4(0.25, 0.25, 0.35, 1.0);
uniform vec4 border_color : source_color = vec4(0.4, 0.4, 0.6, 1.0);
uniform float border_thickness : hint_range(0.0, 0.2) = 0.08;
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float scanline_speed : hint_range(0.0, 2.0) = 0.5;

// 危险平台专用
uniform bool is_hazard : hint_range(0.0, 1.0) = false;
uniform vec4 hazard_color : source_color = vec4(0.9, 0.15, 0.15, 1.0);
uniform vec4 hazard_glow : source_color = vec4(0.9, 0.15, 0.15, 0.0);

// 移动平台专用
uniform bool is_moving : hint_range(0.0, 1.0) = false;
uniform vec4 moving_color : source_color = vec4(0.2, 0.7, 1.0, 1.0);
uniform vec4 moving_glow : source_color = vec4(0.2, 0.7, 1.0, 0.0);

// 翻转时的缩放
uniform float flip_scale_y : hint_range(-1.0, 1.0) = 1.0;

void fragment() {
    // UV 标准化
    vec2 uv = UV;
    
    // 扫描线动画
    float scan = sin((uv.y + TIME * scanline_speed) * 30.0) * 0.5 + 0.5;
    
    // 边缘检测
    float edge_x = min(uv.x, 1.0 - uv.x) / border_thickness;
    float edge_y = min(uv.y, 1.0 - uv.y) / border_thickness;
    float edge = min(edge_x, edge_y);
    
    // 描边
    float border = smoothstep(1.0, 0.0, edge);
    
    // 内部渐变
    float inner = smoothstep(1.0, 0.3, edge) - smoothstep(0.3, 0.0, edge);
    
    // 颜色选择
    vec4 col = platform_color;
    vec4 glow = border_color;
    
    if (is_hazard) {
        col = mix(platform_color, hazard_color, 0.7);
        glow = hazard_glow;
        // 危险平台闪烁
        float flash = sin(TIME * 6.0) * 0.5 + 0.5;
        glow.a *= (0.7 + flash * 0.3);
    }
    elif (is_moving) {
        col = mix(platform_color, moving_color, 0.7);
        glow = moving_glow;
    }
    
    // 扫描线叠加
    col.rgb += scan * 0.03;
    
    // 描边发光
    col = mix(col, glow, border * glow_intensity);
    
    // 边缘高亮
    col.rgb += border * 0.15;
    
    COLOR = col;
    COLOR.a = max(inner * 0.9, border * 0.7);
}
