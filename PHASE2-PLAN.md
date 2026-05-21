# Phase 2 · Stereo Parallax 方案对比

> Phase 1 = head-tracked **motion parallax**（屏幕作"窗户"，跟头动）；单眼也有立体感。
> Phase 2 = **stereo parallax**（让左右眼分别看到不同视角，叠加双目视差立体）。

## 现实约束：硬件做不到什么

普通 MacBook LCD **没有分光机制**（无视差屏 / 无透镜屏 / 无偏振屏 / 无 120Hz 快门屏），单纯靠屏幕本身让两只眼看到不同内容**物理上不可能**。Phase 2 能跑通的 3 条路径：

| 方案 | 原理 | 硬件 | 难度 | 已实现 |
|---|---|---|---|---|
| **A. SBS 自由立体** | 屏幕分左右两半画两个视角，用户斗鸡眼/平行眼合成 | 零硬件，要练眼 | 中 | ✅ `index_stereo.html` |
| **B. Anaglyph 红蓝立体** | 左视图红通道，右视图青通道叠加 | 5 块钱红蓝眼镜 | 低 | ⏳ 接口已预留 |
| **C. 眼球追踪假分光** | 假设头不动，屏幕左半只显示左眼内容、右半只显示右眼内容 | 零硬件，但头动就崩 | 低（不稳） | ❌ 放弃 |

## 当前实现：方案 A（SBS 自由立体）

### 文件

- `index.html` — Phase 1（motion parallax only），保留不动
- `index_stereo.html` — Phase 2（SBS 立体 + 头动追踪）✨

### 关键算法实现

#### 1. 双相机
```js
const cameraL = makeCam();   // 左眼物理位置 (eye.ex - IPD/2, eye.ey, eye.ez)
const cameraR = makeCam();   // 右眼物理位置 (eye.ex + IPD/2, eye.ey, eye.ez)
```

#### 2. 各自 off-axis 对着"半屏幕"
每个相机的 frustum 不是对着整个屏幕，而是**屏幕对应的物理一半矩形**：
- cameraL 物理对应 → 屏幕左半 (-w, -h)..(0, h)
- cameraR 物理对应 → 屏幕右半 (0, -h)..(w, h)

这样 viewport（屏幕物理半边）的 aspect 与 frustum 一致，画面不被横向压缩。

#### 3. 双 viewport 渲染（带 scissor 测试）
```js
renderer.autoClear = false;
renderer.clear();
renderer.setScissorTest(true);

// 屏幕左半 viewport（cross-eyed 模式：给 cameraR 的视图）
renderer.setViewport(0, 0, halfW, H);
renderer.setScissor(0, 0, halfW, H);
renderer.render(scene, stereoMode === 'cross' ? cameraR : cameraL);

// 屏幕右半 viewport
renderer.setViewport(halfW, 0, halfW, H);
renderer.setScissor(halfW, 0, halfW, H);
renderer.render(scene, stereoMode === 'cross' ? cameraL : cameraR);

renderer.setScissorTest(false);
```

#### 4. 双重视差叠加
- **Stereo 视差**：cameraL 和 cameraR 间距 = IPD × stereoScale，自然产生双目视差
- **Motion 视差**（来自 Phase 1）：head 位置每帧从 MediaPipe 估出，eye 跟着动，整组双相机一起平移 → 头动时画面也跟着变

两种视差叠加 = **stereoscopic + motion parallax**，效果优于单纯任一种。

### 用户操作

| 键 | 作用 |
|---|---|
| `S` | Stereo 模式 cross → parallel → mono 循环 |
| `,` `.` | 立体强度 ±0.1（0=平面 / 1=真实 IPD / 2=夸张） |
| `Space` | 零位校准 |
| `[ ]` `- =` `; '` | FoV / IPD / Cam Y 微调（同 Phase 1） |
| `R` | 全部重置 |

### 自由立体观看方法

1. **斗鸡眼（cross-eyed）**：屏幕中央有两个蓝色小圆点，盯住两点中间慢慢"对眼"，直到左右两点重叠成 3 个点 → 中间那个是大脑合成的 3D 画面
2. **平行眼（parallel）**：把目光"放远"看屏幕后方，类似 Magic Eye 隐藏立体图
3. **练习不会**：按 `S` 切到 mono，退化为 Phase 1 单画面（仍有 motion parallax）

## 后续可选迭代

### B. Anaglyph 红蓝立体（5 分钟切换）
基础设施已就位（双相机 + 双 off-axis projection），只需替换 renderStereo() 渲染方式：把 cameraL 渲染到 R 通道、cameraR 渲染到 GB 通道（用 `ColorMaskMaterial` 或 `THREE.AnaglyphEffect`）。戴红蓝眼镜直接看 3D。

### 加 USB 宽角 webcam
内置摄像头 FoV ~55°，贴近屏幕时容易丢追踪。外接 90° 摄像头能扩大有效工作距离至 70cm+。

### 6DoF 头位估计升级
当前用"双眼像素位置 + IPD 反推"求头位。改用 MediaPipe `outputFacialTransformationMatrixes=true` 直接拿 6DoF 变换矩阵（含 yaw/pitch/roll），头部大幅旋转时更稳定。

### "屏幕成画框"装饰
画一个有质感的物理画框（木纹 / 金属边），强化"窗户感"——立体效果会更强烈。

## 工程注意点

1. **renderer.autoClear = false + 手动 clear**：双 viewport 渲染必须，否则第二次 render 覆盖第一次
2. **setScissorTest(true)**：限制每次 render 只画 viewport 区域内的像素（包括 clear color）
3. **两个相机都必须 `projectionMatrixAutoUpdate = false`**（继承 Phase 1 教训）
4. **stereoScale = 0 时退化为单相机**：左右画面完全一致，验证 SBS 几何正确性的最简方式
5. **cross vs parallel 选哪个**：cross-eyed 一般更容易学（大脑天然倾向聚焦近处），但视野较小；parallel 视野大但需要训练

## 评估方法

让川哥试 5 种状态：
1. `mode=mono, scale=0` → 应该完全等同 Phase 1
2. `mode=cross, scale=0` → 两半画面完全相同（视差为 0），平面感
3. `mode=cross, scale=1.0` → 真实 IPD 视差，最自然立体感
4. `mode=cross, scale=2.0` → 夸张立体（容易眼疲劳但效果最猛）
5. `mode=parallel, scale=1.0` → 反向观看体验

主观打分哪个最强 3D 感。
