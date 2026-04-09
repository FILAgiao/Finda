# Finda 项目蓝图 (Project Blueprint)

> 这是 AI 的"记忆宫殿大厅"——所有工作的起点和上下文来源

## 项目定位
Finda 是一款智能匹配类 App，连接需求方与服务提供者。

## 当前阶段
🔄 MVP 开发期 (预计 6-8 周)

## 核心架构
```
📱 移动端
  ├── Android (原生/Kotlin)
  └── iOS (原生/Swift)

☁️ 后端
  ├── 用户服务
  ├── 匹配算法服务
  └── 支付/结算服务

🤖 AI 能力
  ├── 智能匹配推荐
  └── 内容审核
```

## 技术决策记录 (ADR)
| 日期 | 决策 | 状态 | 文档 |
|------|------|------|------|
| 2026-04-09 | 移动端采用原生开发 | ✅ 已决定 | [ADR-001](decisions/ADR-001-native-development.md) |

## 快速导航 (记忆宫殿地图)
- 🎯 当前 Sprint → [sprints/current.md](sprints/current.md)
- 📋 需求 backlog → [backlog/](backlog/)
- 🧠 用户洞察 → [insights/](insights/)
  - [心理学画像](insights/psychology-map/persona.md)
  - [情绪地图](insights/journey-emotion/map.md)
  - [增长实验](insights/experiments/README.md)
- ✅ 任务列表 → [`.claude/tasks/`](../.claude/tasks/)
- 🧠 项目记忆 → [`.claude/memory/`](../.claude/memory/)

## 关键指标 (OKR)
- O1: 完成 MVP 核心流程
  - KR1: 用户注册-匹配-下单完整闭环
  - KR2: 匹配准确率 > 70%
  - KR3: 端到端响应时间 < 3s

## AI 协作规则
1. 每次对话先读取本文件获取上下文
2. 代码改动必须关联 backlog 中的需求
3. 技术决策必须创建 ADR 文档
4. 任务完成自动更新状态
