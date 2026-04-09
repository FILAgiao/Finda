# Finda (饭达/饭搭)

> AI配对，你想要搭子，月老都懂你

## 项目简介

Finda 是一款基于AI的约会撮合平台，旨在解决约会市场的效率问题。

### 核心创新

- **唯一推送机制**：一天只推一个人，月老点名就是他
- **诚意金质押**：防鸽机制，降低爽约率
- **隐私保护**：暗池交易模式，信息只对匹配者可见
- **时间匹配硬件化**：时间前置刚性约束，消除沟通成本

## 快速导航

| 文档 | 内容 | 用途 |
|------|------|------|
| [📋 项目总览](PLAN.md) | 蓝图、架构、指标 | 每次对话先读 |
| [🏰 记忆宫殿](MEMORY_PALACE.md) | 空间导航地图 | 快速定位信息 |
| [📊 实施报告](IMPLEMENTATION_REPORT.md) | 完整实施报告 | 了解体系全貌 |
| [🔧 AI规则](.cursorrules) | AI协作规范 | 自动执行 |

### 需求管理
- [📋 Backlog](backlog/README.md) - 需求管理（Epic-Story-Task）
- [🧠 用户洞察](insights/) - 心理学画像、情绪地图、增长实验
- [🧪 Sprint](sprints/current.md) - 当前迭代

### 技术文档
- [📐 产品设计](./docs/finda-product-design.md)
- [🔍 撮合算法](./docs/finda-matching-algorithm.md)
- [🏗️ 技术架构](./docs/technical-architecture.md)
- [⚖️ 决策记录](decisions/) - ADR

### 快捷脚本
```bash
# Mac/Linux
./scripts/finda.sh status    # 查看项目状态
./scripts/finda.sh insights  # 查看用户洞察
./scripts/finda.sh story US-001  # 查看Story

# Windows
scripts\finda.bat status
```

## 项目管理体系

本项目采用**心理学驱动**的 AI 增强型项目管理：

### 三层架构
```
Epic（大模块） → Story（用户价值） → Task（执行单元）
```

### 心理学洞察
基于行为心理学设计产品：
- **损失厌恶** → 强调"防鸽"而非"约饭"
- **决策瘫痪** → 每天只推一人
- **稀缺性** → 限时匹配、过期不候
- **峰终定律** → 精心设计的匹配成功体验

📖 详见 [insights/psychology-map/persona.md](insights/psychology-map/persona.md)

### 增长实验
每个功能都有可验证的假设：
- EXP-001: 等待可视化减少焦虑
- EXP-002: 单推荐提升匹配率
- EXP-004: 损失框架提升注册率

📖 详见 [insights/experiments/README.md](insights/experiments/README.md)

## 技术栈

- **平台**: Android (Kotlin) & iOS (Swift) - 原生开发
- **核心算法**: KM算法（完全二分图最大权匹配）
- **AI能力**: 大模型意图解析、用户画像、智能推荐
- **项目管理**: Markdown + AI + 心理学驱动

## 目标用户

公务员、教师、精英阶层 —— 需要"高效、体面、唯一"的约会解决方案

## OKR

- **O1**: 完成 MVP 核心流程
  - KR1: 用户注册-匹配-见面完整闭环
  - KR2: 匹配准确率 > 70%
  - KR3: 爽约率 < 10%

## Slogan

**一天只推一个人，月老点名就是他。**

---

*这不是社交软件，这是精准的缘分投递。*

---

## 最近更新

**2026-04-09**: 建立完整的项目管理体系
- ✅ 三层需求管理（Epic-Story-Task）
- ✅ 用户心理画像与情绪地图
- ✅ 5个增长实验设计
- ✅ AI协作规则与自动化脚本
- ✅ ADR决策记录机制
