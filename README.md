# Gravity Runner 🛺

轻量重力翻转无尽跑酷游戏，Godot 4 + 手写 Shader。

## 运行方式

```bash
# 命令行验证（headless 模式）
godot --headless --path gravity_runner

# 下载 Godot 4.4 编辑器导入项目文件夹
# https://godotengine.org/download
```

## 操作

- **空格键** - 翻转重力
- 躲避障碍，站上平台，看你能跑多远

## 项目结构

```
gravity_runner/
├── project.godot          # 项目配置（540×960竖屏）
├── shaders/
│   ├── player_glow.gdshader    # 玩家：发光圆形 + 呼吸脉冲
│   ├── platform_glow.gdshader  # 平台：描边发光 + 扫描线
│   ├── flip_ring.gdshader      # 翻转：扩散光环
│   ├── trail.gdshader          # 拖尾：渐隐效果
│   └── starfield.gdshader      # 背景：视差星空
├── scripts/
│   ├── main.gd               # 主场景 & 游戏流程
│   ├── game_manager.gd       # 状态 + 难度曲线（Sigmoid 1.0→2.6）
│   ├── player.gd             # 重力翻转 + 落地squash + coyote time
│   ├── platform.gd           # 平台（普通/移动/危险）
│   ├── platform_generator.gd # 可达性保证的无尽生成
│   ├── screen_shake.gd       # 屏幕震动
│   ├── ui.gd                # 分数/最高分/开始/结束界面
│   └── flip_particles.gd     # 翻转粒子控制器
└── scenes/
    ├── main.tscn              # 主场景
    ├── player.tscn            # 玩家节点（含 ShaderMaterial）
    ├── platform.tscn          # 平台节点（含 ShaderMaterial）
    └── flip_particles.tscn    # 翻转粒子
```

## 视觉效果

| Shader | 效果 |
|--------|------|
| **player_glow** | 发光圆形，呼吸脉冲，上下翻转时y轴镜像 |
| **platform_glow** | 描边发光，扫描线动画，危险/移动平台变色 |
| **flip_ring** | 翻转时扩散光环，渐隐消失 |
| **trail** | 拖尾渐隐，从新到旧自然淡出 |
| **starfield** | 视差滚动星空，双层闪烁 |

## 难度设计

- Sigmoid 曲线：15s 学习期 → 60s 高压期 → 无限模式
- 分数 = 时间 × 12 × 难度^0.7

## 待优化

- [ ] 音效与音乐
- [ ] 成就系统
- [ ] 安卓/微信小游戏导出
