# head-tracked-3d-demo · Phase 1

MacBook 浏览器版"头动视差 3D"Demo（Johnny Lee Wii Remote 范式）。

> 注意：这**不是**双目视差裸眼 3D（普通 LCD 屏没有分光机制，做不到）。
> 这是 **head-tracked motion parallax**：屏幕作为"窗户"，根据观察者头部位置实时改变 off-axis 投影矩阵；单眼也有强烈立体感。

## 技术栈
- MediaPipe Face Landmarker (Tasks Vision v0.10.14)
- Three.js r160
- WebGL 2，无后端，零安装

## 跑起来

```bash
cd 2-Projects/head-tracked-3d-demo
./start.sh
# 浏览器打开 http://localhost:8765
```

`getUserMedia` 需要 https 或 localhost——localhost 直接放行。

## 标定参数（在 index.html 顶部 PHYS 常量）
- `ipdMm`：默认 63mm 人群均值，瞳距小的人会被估远，可微调
- `screenWmm` / `screenHmm`：屏幕物理尺寸（13"~14" 约 30×19cm）
- `camOffsetYmm`：摄像头比屏幕几何中心高多少（≈ 屏幕高度的一半 + 摄像头模块到屏幕上沿距离）
- `camHFovDeg`：MacBook 摄像头水平 FoV，55° 是经验值，不同年代略差

## 关键算法
- 头位估计：双眼像素坐标 + 假设真实 IPD → 反推头到摄像头距离（针孔模型 `z = fx * IPD_real / IPD_px`）
- 投影矩阵：`THREE.Matrix4.makePerspective(left, right, top, bottom, near, far)`，每帧根据眼睛位置重新计算 asymmetric frustum 四边
- 防抖：OneEuro filter（cc-AirPlayer v4.9 同款思路）

## 已知限制（Phase 1 范围）
- 单 IPD 假设：人群方差 ±3mm → 距离估计 ±5%
- 摄像头位置写死：不同 MacBook 实际偏移略不同
- 头大幅转动会丢追踪
- 光线很暗时 landmarker 精度掉
- 普通 60Hz LCD 没有立体光学结构，强光下"窗户"破绽明显

## Phase 2 预留
- 双瞳独立 3D 估计已经在管线里，加红蓝立体眼镜即可双目视差
- 可外接 USB webcam 替代内置摄像头（更宽 FoV，效果更好）
