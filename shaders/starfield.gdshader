shader_type canvas_item;

// 背景星空 shader
uniform vec3 star_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float star_density : hint_range(0.0, 0.01) = 0.003;
uniform float twinkle_speed : hint_range(0.0, 5.0) = 1.5;
uniform float parallax_depth : hint_range(0.0, 1.0) = 0.3;

// 渐变层
uniform vec4 top_color : source_color = vec4(0.05, 0.05, 0.12, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.08, 0.05, 0.15, 1.0);

// 移动速度（模拟向上飞）
uniform float scroll_speed : hint_range(0.0, 1.0) = 0.05;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    // 背景渐变
    vec4 bg = mix(bottom_color, top_color, UV.y);
    
    // 星空
    float density = star_density * 1000.0;
    vec2 grid = floor(UV * density);
    float star_rand = hash(grid);
    
    // 星星分布
    float star_mask = step(1.0 - star_density * 100.0 / density * 0.5, star_rand);
    
    // 闪烁
    float twinkle = sin(TIME * twinkle_speed * (0.5 + star_rand) + star_rand * 6.28) * 0.5 + 0.5;
    
    // 视差滚动
    vec2 scrolled_uv = UV;
    scrolled_uv.y += TIME * scroll_speed;
    float star_rand2 = hash(floor(scrolled_uv * density));
    float star_mask2 = step(1.0 - star_density * 80.0 / density * 0.3, star_rand2);
    float twinkle2 = sin(TIME * twinkle_speed * 0.7 * (0.5 + star_rand2) + star_rand2 * 6.28) * 0.5 + 0.5;
    
    // 组合星星
    float stars = star_mask * (0.3 + twinkle * 0.7) * 0.8;
    stars += star_mask2 * (0.2 + twinkle2 * 0.5) * 0.5;
    
    vec3 col = bg.rgb + star_color * stars;
    
    COLOR = vec4(col, bg.a);
}
