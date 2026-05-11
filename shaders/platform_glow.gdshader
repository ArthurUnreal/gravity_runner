shader_type canvas_item;

// 平台发光边框 shader - 用 texture_size * scale 算实际像素坐标

uniform vec4 platform_color : source_color = vec4(0.25, 0.25, 0.35, 1.0);
uniform vec4 border_color : source_color = vec4(0.4, 0.4, 0.6, 1.0);
uniform float border_thickness : hint_range(0.0, 1.0) = 0.06;
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float scanline_speed : hint_range(0.0, 5.0) = 1.0;

uniform bool is_hazard : hint_range(0.0, 1.0) = false;
uniform vec4 hazard_color : source_color = vec4(0.9, 0.15, 0.15, 1.0);

uniform bool is_moving : hint_range(0.0, 1.0) = false;
uniform vec4 moving_color : source_color = vec4(0.2, 0.7, 1.0, 1.0);

uniform float flip_scale_y : hint_range(-1.0, 1.0) = 1.0;

void fragment() {
    // 用 texture_size * scale 算 sprite 实际像素尺寸
    vec2 pixel_size = TEXTURE_PIXEL_SIZE;
    vec2 size_px = vec2(texture_size(TEXTURE, 0)) * (vec2(1.0) / pixel_size);
    
    // UV 标准化到 [-1, 1]
    vec2 centered = (UV - vec2(0.5)) * 2.0;
    centered.y /= flip_scale_y;
    
    // 到边缘距离（归一化，1=到角）
    float edge_x = 1.0 - abs(centered.x);
    float edge_y = 1.0 - abs(centered.y);
    float edge_dist = min(edge_x, edge_y);
    
    // 描边
    float border = smoothstep(border_thickness, 0.0, edge_dist);
    
    // 内部
    float inner = smoothstep(1.0, border_thickness * 3.0, edge_dist);
    
    // 扫描线
    float scan = sin(centered.y * 20.0 + TIME * scanline_speed) * 0.5 + 0.5;
    
    // 颜色
    vec4 col = platform_color;
    if (is_hazard) {
        float flash = sin(TIME * 6.0) * 0.5 + 0.5;
        col = mix(platform_color, hazard_color, 0.6 + flash * 0.4);
    } elif (is_moving) {
        col = mix(platform_color, moving_color, 0.6);
    }
    
    // 扫描线叠加
    col.rgb += scan * 0.03 * inner;
    
    // 描边
    col.rgb = mix(col.rgb, border_color.rgb, border * glow_intensity);
    col.rgb += border * 0.15;
    
    float alpha = max(inner * 0.9, border * 0.75);
    COLOR = col;
    COLOR.a = alpha;
}
