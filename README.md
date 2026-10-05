<div align="center">

![Bugaoshan](https://socialify.git.ci/nanakinker/Bugaoshan/image?custom_description=%E5%B7%9D%E5%A4%A7%E6%A0%A1%E5%9B%AD%E5%8A%A9%E6%89%8B%20%C2%B7%20%E6%B6%B2%E6%80%81%E7%8E%BB%E7%92%83%E5%AE%9E%E9%AA%8C%E7%89%88%EF%BC%9A%E8%AF%BE%E8%A1%A8/%E6%88%90%E7%BB%A9/%E7%AC%AC%E4%BA%8C%E8%AF%BE%E5%A0%82%E4%B8%80%E7%AB%99%E5%BC%8F%E8%81%9A%E5%90%88%EF%BC%8C%E5%AF%BC%E8%88%AA%E6%A0%8F%E4%B8%8E%E9%A1%B6%E6%A0%8F%E9%87%87%E7%94%A8%20Liquid%20Glass%20%E6%9D%90%E8%B4%A8&custom_language=Flutter&description=1&font=Bitter&forks=1&issues=1&language=1&logo=https%3A%2F%2Fraw.githubusercontent.com%2Fnanakinker%2FBugaoshan%2Frefs%2Fheads%2Ffeat%2Fliquid-glass-dock%2Fassets%2Ficon.png&name=1&owner=1&pattern=Signal&pulls=1&stargazers=1&theme=Auto)

# 🏔️ 不高山上 · Bugaoshan

[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-AGPL3.0-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%E2%9C%93-34a853?logo=android&logoColor=white)](https://flutter.dev)
[![Status](https://img.shields.io/badge/Status-Experimental-orange)](https://github.com/nanakinker/Bugaoshan/releases)

> 川大学生专属校园助手 · **液态玻璃实验版**

<div align="center">

**🧪 这是[官方仓库](https://github.com/The-Brotherhood-of-SCU/Bugaoshan)的个人 fork 分支**，
将导航栏与课表顶栏重构为 **Liquid Glass（液态玻璃）**材质。
当前**仅支持安卓手机**，属实验性版本。详见[下载](#-下载)与
[Release 说明](https://github.com/nanakinker/Bugaoshan/releases)。

</div>

</div>

---

## 📖 背景

**不高山上**（Bugaoshan）是由 **The-Brotherhood-of-SCU** 团队开发的一款面向四川大学学生的校园助手 App。

"不高山"是江安校区的一处标志性地标，App 以此命名，寓意扎根校园、服务同学。

### 🧪 关于这个 fork

本仓库是上游项目的个人实验分支，聚焦**液态玻璃（Liquid Glass）界面的重构**：

- 导航栏、课表顶栏改用 [`liquid_glass_widgets`](https://pub.dev/packages/liquid_glass_widgets)
  的液态玻璃材质，背景内容透过玻璃透出并被**折射、色散**
- 页面改用 `GlassScaffold` 承载，为玻璃提供受控的背景采样源
- 修复了若干上游问题（背景图不显示、平板侧栏残影、深色模式状态栏不可见等）

功能与官方版本一致，**改动仅限于界面材质**。上游更新可通过 `git merge upstream` 同步。

---

## 🎨 界面风格

导航条与顶栏采用**液态玻璃**视觉语言，基于社区包
[`liquid_glass_widgets`](https://pub.dev/packages/liquid_glass_widgets) 实现
（fragment shader + Impeller 渲染管线）。核心是「让背景透出来，并被折射」。

### 架构：GlassScaffold + 玻璃导航层

页面使用包提供的 **`GlassScaffold`** 而非 Flutter 的 `Scaffold`。这不是风格选择，
而是玻璃能否正确渲染的前提——玻璃需要**受控的背景源**才能计算折射与色散，
`GlassScaffold` 负责背景采样源、渲染层与 z-order：

```
GlassScaffold
├── background        背景采样源（折射/色散必须有可采样的内容）
├── contentAwareBrightness  按背后内容实际明暗自动翻转图标颜色
├── statusBarStyle    状态栏图标按主题取色
└── bottomBar: GlassTabBar   悬浮药丸导航条
```

> 早期实现把 `GlassTabBar` 塞进 Material `Scaffold`，玻璃背后没有受控背景源，
> 折射与色散无法计算，观感与官方 demo 明显不同。

### 玻璃质感

- **折射与色散**：玻璃边缘把背后内容压缩位移，产生红蓝色散彩边——玻璃感的主要来源
- **滑动玻璃透镜**：选中态是**独立于导航条本体、在各导航项之间流动的玻璃透镜**，
  滑动途中按体积守恒挤压拉伸，停下后回弹
- **全药丸形**：底部导航呈完整胶囊形悬浮，左右留出与屏宽成比例的边距，
  让背景从两侧透出
- **顶栏浮层**：课表页左上角的时间/周次框与右侧动作区各是一块**独立玻璃**，
  深浅色下与底栏使用同一套材质参数
- **有色玻璃课表格**：课表格子保留课程色（保证快速扫读）但改为半透明玻璃

### 材质参数集中管理

全应用四处玻璃（底部导航、顶栏时间框、顶栏动作区、宽屏侧边栏）共用
`lib/widgets/common/app_glass.dart` 中的同一份 `LiquidGlassSettings`。
光学参数（thickness / blur / refractiveIndex / chromaticAberration 等）
与库的 `kBottomBarGlassDefaults` 保持一致，**仅底纱色按深浅色切换**。

> 参数不能各写各的：此前浅色底纱一度出现 24% 与 55% 两种值，导致顶栏明显
> 比底栏黑。集中管理后改一处即全应用同步。

### 性能取舍

玻璃效果按「内容是否会形变」分档，避免在常驻可见的静态内容上跑高开销 shader：

| 部位 | 质量档 | 理由 |
| --- | --- | --- |
| 底部 / 侧边导航条、顶栏玻璃 | `premium` | 切换时形变，需要折射与色散 |
| 页面卡片、设置项图标、弹窗 | 自绘 `BackdropFilter` | 静态内容，描边与高光自绘，不跑 shader |

课表格子与列表项全项目 80+ 处复用，若每张都跑 fragment shader 会直接拖垮
性能，因此按包的官方建议（玻璃只用于导航与控件层）保持自绘。

页面切换为瞬时，动效只保留在导航条透镜上；课表背景层加 `RepaintBoundary`，
避免内容重绘时连带全屏大图重新光栅化。

### 效果预览

导航条悬浮在课表上方时，玻璃会把背景的彩色课程块折射出层次——
既能看出下方是课表内容，又不影响导航文字的可读性。

<div align="center">
  <img src="./screenshot/screenshot-dock-course-light.webp" width="30%" />
  &nbsp;&nbsp;&nbsp;
  <img src="./screenshot/screenshot-dock-course-dark.webp" width="30%" />
  &nbsp;&nbsp;&nbsp;
  <img src="./screenshot/screenshot-dock-campus-light.webp" width="30%" />
  &nbsp;&nbsp;&nbsp;
  <img src="./screenshot/screenshot-dock-campus-dark.webp" width="30%" />
  &nbsp;&nbsp;&nbsp;
</div>

*依次为：课表（浅色 / 深色）、校园（浅色 / 深色）
---

## ✨ 主要功能

- **课表管理** — 从教务处等多来源导入课表，清晰掌握每日课程安排，支持多课表一键快捷切换，还有课表小组件方便查看
- **课表导出** — 导出课表为 ICS 日历文件，一键导入到系统日历，也可复制到剪切板
- **成绩统计** — 查看个人成绩，支持自定义统计与通过率分析，直观了解学业情况
- **方案修读情况查询** — 查询个人修读的方案，了解学习进度，支持多份方案（主修/辅修/微专业）切换查看
- **培养方案** — 查询各年级学院的培养方案详情
- **在线报修** — 在 App 内提交宿舍报修工单（选地址/维修项目、上传照片、预约时间），随时查看处理进度，支持撤回与评价工单
- **校园网无感认证** — 绑定设备 MAC 地址后接入校园网自动认证，告别手动登录
- **第二课堂** — 查看、参与和预约第二课堂活动
- **考表查询** — 查询个人考试信息，了解考试安排
- **体测查询** — 查询个人体测记录，了解体测结果
- **空闲教室查询** — 实时查询校园内各楼栋的空闲教室情况，方便自习选座
- **校园网设备查询** — 查看和下线当前账号在线的校园网设备
- **余额查询** — 查询校园卡、网费、寝室电费及空调余额，支持历史趋势分析
- **校历查询** — 查询校园的校历，了解放假安排
- **班级/课程课表查询** — 查询各个年级和班级的课表以及课程课表，方便查看课程安排
- **通知公告、附件下载** — 查看教务处、党委学工部、青春川大通知公告以及下载附件
- **志愿四川** — 志愿四川查询和报名
- **请假报备** — 请假、寒暑假留校/离校报备
- **个性化设置** — 主题颜色、课程表样式、字体、应用图标、动画时长等自定义选项
- **更多便捷功能** — 持续迭代中，更多校园实用工具即将上线

<div align="center">
  <img src="./screenshot/screenshot-course.webp" width="30%" />
  &nbsp;&nbsp;&nbsp;
  <img src="./screenshot/screenshot-campus.webp" width="30%" />
  &nbsp;&nbsp;&nbsp;
  <img src="./screenshot/screenshot-widget.webp" width="30%" />
</div>


## 📥 下载

**前往 [Release 页面](https://github.com/The-Brotherhood-of-SCU/Bugaoshan/releases/latest) 下载最新版本**

> 📱 **iOS 与鸿蒙版本正在邀测中**，欢迎加入官方QQ群（1102483776）参与测试

### 🧪 液态玻璃实验版（个人构建）

本仓库 `feat/liquid-glass-dock` 分支上的**液态玻璃版本**为个人实验构建，
仅支持**安卓手机**，不含 iOS / Windows / macOS / 安卓平板。

- 📦 [下载 Release（仅安卓手机）](https://github.com/nanakinker/Bugaoshan/releases)
- 安装包已用 `apksigner` 签名，**开箱即装，请勿再用第三方工具二次签名**
  （重打包会破坏 Flutter 应用的图片解码，导致背景图异常）
- 签名与官方不同，覆盖安装前需先卸载官方版
- 这是实验性版本，可能存在尚未发现的 Bug，欢迎反馈

---

## 🖼️ 自选课表背景图

在「我的 → 设置 → 课程表样式 → 设置背景图片」可从相册选一张图片作为课表背景。

**几个实用建议**：

| 建议 | 说明 |
| --- | --- |
| 选柔和低对比的图片 | 课表格子默认带半透明白色遮罩，图片对比越低越清晰 |
| 不透明度调25%~40% | 低于 20% 图片过淡，高于 50% 格子开始抢眼 |
| 用「调整显示区域」裁剪 | 把想看的部分放中央，比整张铺满好看 |
| 优先竖构图 | 手机屏是竖的，横图铺满后主体容易被裁 |
| 深色主题配暗色系图片 | 浅色图片配深色主题会刺眼且文字对比不足 |

可随时「移除背景图片」或「重置为默认」恢复。

---

## 🛠️ 开发

如需参与开发或自行编译，请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 了解环境配置、构建命令等详细指引；当前架构与设计决策见 [工程文档](docs/README.md)。

### 🧪 构建本 fork 的注意事项

```bash
# 1. 先构建官方 release 版（避免中文路径影响 Gradle）
D:\devtoolsuild-bugaoshan.cmd --release

# 2. 用官方 apksigner 签名 —— 请勿用第三方工具二次签名
#    第三方签名会重打包 APK，改变 ZIP 内文件偏移，
#    Flutter 的图片索引解码会失效（表现为背景图错乱或空白）
```

Release 资产已由 `zipalign` + `apksigner` 处理，**开箱即装**。

---

## 💖 致谢与贡献者

感谢所有为 **不高山上 / Bugaoshan** 做出贡献的开发者与社区成员！

本 fork 的改动由个人完成，界面重构思路参考了社区包
[`liquid_glass_widgets`](https://pub.dev/packages/liquid_glass_widgets) 提供的官方规范。

**上游项目的全部贡献者**（本 fork 基于其代码）：

[![Contributors](https://contrib.rocks/image?repo=The-Brotherhood-of-SCU/Bugaoshan)](https://github.com/The-Brotherhood-of-SCU/Bugaoshan/graphs/contributors)

---

## 📜️ 许可证

本项目基于 [AGPL-3.0](LICENSE) 协议开源。使用本软件前请阅读 [EULA](assets/eula.md)。

本项目使用了多项优秀的开源组件，详细列表及对应的开源协议请参阅 [pubspec.yaml](pubspec.yaml) 文件。
