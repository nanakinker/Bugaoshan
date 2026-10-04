<div align="center">

![Bugaoshan](https://socialify.git.ci/The-Brotherhood-of-SCU/Bugaoshan/image?custom_description=%E4%B8%8D%E9%AB%98%E5%B1%B1%E4%B8%8AAPP%EF%BC%9A%E5%9B%9B%E5%B7%9D%E5%A4%A7%E5%AD%A6%E8%AF%BE%E8%A1%A8%E3%80%81%E6%88%90%E7%BB%A9%E3%80%81%E7%AC%AC%E4%BA%8C%E8%AF%BE%E5%A0%82%E3%80%81%E5%BE%AE%E6%9C%8D%E5%8A%A1%E4%B8%80%E7%AB%99%E5%BC%8F%E8%81%9A%E5%90%88%E5%B7%A5%E5%85%B7%E9%9B%86&custom_language=Flutter&description=1&font=Bitter&forks=1&issues=1&language=1&logo=https%3A%2F%2Fraw.githubusercontent.com%2FThe-Brotherhood-of-SCU%2FBugaoshan%2Frefs%2Fheads%2Fmain%2Fassets%2Ficon.png&name=1&owner=1&pattern=Signal&pulls=1&stargazers=1&theme=Auto)

# 🏔️ 不高山上 · Bugaoshan

[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-AGPL3.0-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Android%20%7C%20Windows%20%7C%20macOS-blue)](https://flutter.dev)

> 川大学生专属校园助手

</div>

---

## 📖 背景

**不高山上**（Bugaoshan）是由 **The-Brotherhood-of-SCU** 团队开发的一款面向四川大学学生的校园助手 App。

"不高山"是江安校区的一处标志性地标，App 以此命名，寓意扎根校园、服务同学。

---

## 🎨 界面风格

导航条与卡片采用**液态玻璃**视觉语言，基于社区包
[`liquid_glass_widgets`](https://pub.dev/packages/liquid_glass_widgets) 实现
（fragment shader + Impeller 渲染管线）。核心是「让背景透出来，并被折射」：

- **折射与色散**：玻璃边缘会把背后的内容压缩位移，产生红蓝色散彩边——
  这是玻璃感的主要来源，由 `refractiveIndex` 与 `chromaticAberration` 控制
- **滑动玻璃透镜**：选中态不是固定色块，而是一枚**独立于导航条本体、在各导航项之间
  流动的玻璃透镜**。滑动途中按体积守恒挤压拉伸——宽度增加时高度反向收缩、
  圆角同步变大，形状由圆角方形过渡为胶囊，停下后回弹
- **全药丸形**：底部导航呈完整胶囊形悬浮于屏幕下方，左右留出与屏宽成比例的边距，
  让背景从两侧透出，强化「悬浮的一块玻璃」的观感
- **有色玻璃课表格**：课表格子保留课程色（保证快速扫读）但改为半透明玻璃，
  叠加顶部高光与内阴影呈现厚度
- **细亮线勾边**：玻璃边缘只留一圈很淡的高光。玻璃感来自「透」与「厚」，
  而不是「亮」——刻意压低了边缘亮度，避免变成发光特效
- **深浅色自适应**：两种主题使用匹配的色调层浓度，保证可读性

可在「设置 → 样式 → 主题样式」中切换 **Material 3 / 液态玻璃** 两种风格。

### 性能取舍

玻璃效果按「内容是否会形变」分档，避免在常驻可见的静态内容上跑高开销 shader：

| 部位 | 质量档 | 理由 |
| --- | --- | --- |
| 底部 / 侧边导航条 | `premium` | 切换时形变，需要折射与色散 |
| 页面卡片、设置项图标、弹窗 | `minimal` | 静态内容，描边与高光自绘 |

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

---

## 🛠️ 开发

如需参与开发或自行编译，请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 了解环境配置、构建命令等详细指引；当前架构与设计决策见 [工程文档](docs/README.md)。

---

## 💖 致谢与贡献者

感谢所有为 **不高山上 / Bugaoshan** 做出贡献的开发者与社区成员！

[![Contributors](https://contrib.rocks/image?repo=The-Brotherhood-of-SCU/Bugaoshan)](https://github.com/The-Brotherhood-of-SCU/Bugaoshan/graphs/contributors)

---

## 📜️ 许可证

本项目基于 [AGPL-3.0](LICENSE) 协议开源。使用本软件前请阅读 [EULA](assets/eula.md)。

本项目使用了多项优秀的开源组件，详细列表及对应的开源协议请参阅 [pubspec.yaml](pubspec.yaml) 文件。
