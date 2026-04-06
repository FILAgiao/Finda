# Finda 技术架构设计文档

> **版本**：V1.0
> **日期**：2026年4月6日
> **作者**：工部技术团队
> **状态**：架构设计

---

## 一、整体架构概览

### 1.1 架构理念

**核心理念**：以"匹配效率"为核心指标，而非"用户停留时长"。

| 传统社交App | Finda |
|------------|-------|
| 目标：最大化DAU/时长 | 目标：最大化撮合成功率 |
| 无限供给 → 决策瘫痪 | 稀缺供给 → 确定性决策 |
| 实时推送 | 批次脉冲式推送 |
| 多线程聊天 | 单线程约会 |

### 1.2 系统架构图

```
┌─────────────────────────────────────────────────────────────────────┐
│                           客户端层 (Client)                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │
│  │  iOS App    │  │ Android App │  │   Web App   │                  │
│  │  (SwiftUI)  │  │  (Kotlin)   │  │   (Next.js) │                  │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                  │
└─────────┼────────────────┼────────────────┼─────────────────────────┘
          │                │                │
          └────────────────┼────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        API Gateway Layer                             │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Kong / AWS API Gateway                   │    │
│  │   • Rate Limiting  • Auth  • SSL Termination  • Routing    │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        服务层 (Microservices)                        │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ 用户服务     │  │ 匹配服务     │  │ 消息服务     │              │
│  │ User Service │  │Match Service │  │ Msg Service  │              │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘              │
│         │                 │                  │                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ 支付服务     │  │ AI意图解析   │  │ 通知服务     │              │
│  │ Pay Service  │  │Intent Engine │  │Push Service  │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ 信用服务     │  │ 地理位置     │  │ 调度服务     │              │
│  │Credit Service│  │ Geo Service  │  │Batch Engine   │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
└─────────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        AI 层 (AI/ML Layer)                          │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ 意图识别     │  │ 向量嵌入     │  │ ELO评分引擎  │              │
│  │ LLM Agent    │  │ Embedding    │  │ Rating Engine │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐                                 │
│  │ KM匹配算法   │  │ 图像审核     │                                 │
│  │Matching Algo │  │Image Moder.  │                                 │
│  └──────────────┘  └──────────────┘                                 │
└─────────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        数据层 (Data Layer)                          │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ PostgreSQL   │  │    Redis     │  │  Elasticsearch│              │
│  │ 主数据存储   │  │ 缓存/队列    │  │ 向量检索      │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ ClickHouse   │  │     S3       │  │    Kafka     │              │
│  │ 分析/日志    │  │ 图片/文件    │  │ 事件流       │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.3 数据流架构

```
用户意图输入 → LLM意图解析 → 向量化 → 存入用户画像
                                          ↓
批次调度器 ← 触发条件（时间/用户数） ← 事件监听
     ↓
Geo-Time过滤 → 向量相似度筛选 → KM全局最优匹配 → 推送候选
                                                      ↓
                                        用户决策 → 诚意金锁定 → 成交/释放
```

---

## 二、技术栈选型

### 2.1 客户端技术栈

| 平台 | 技术选型 | 理由 |
|------|---------|------|
| iOS | SwiftUI + MVVM | 原生性能，快速开发 |
| Android | Kotlin + Jetpack Compose | 现代化UI，协程支持 |
| Web | Next.js 14 + TypeScript | SSR/SSG，SEO友好 |
| 管理后台 | React Admin + Ant Design | 快速搭建 |

### 2.2 后端技术栈

| 组件 | 技术选型 | 理由 |
|------|---------|------|
| 主语言 | Go / Rust | 高并发，低延迟 |
| 框架 | Gin (Go) / Axum (Rust) | 轻量高效 |
| RPC | gRPC | 服务间通信 |
| API网关 | Kong / AWS API Gateway | 成熟稳定 |

### 2.3 数据存储选型

| 数据类型 | 存储选型 | 理由 |
|---------|---------|------|
| 用户主数据 | PostgreSQL | ACID，复杂查询 |
| 会话/缓存 | Redis Cluster | 高性能，过期机制 |
| 向量检索 | Elasticsearch + kNN / Milvus | 语义相似度 |
| 实时地理位置 | Redis Geo + PostGIS | 范围查询 |
| 消息队列 | Kafka | 高吞吐，持久化 |
| 日志分析 | ClickHouse | OLAP，聚合查询 |
| 图片存储 | S3 / OSS | 对象存储 |
| 搜索引擎 | Elasticsearch | 全文检索 |

### 2.4 AI/ML 技术栈

| 功能 | 技术选型 | 理由 |
|------|---------|------|
| 意图解析 | Claude/GPT-4 API | 语义理解能力强 |
| 向量嵌入 | OpenAI Embedding / BGE | 多语言支持 |
| 图像审核 | AWS Rekognition / 自建 | 合规要求 |
| ELO评分 | 自研算法 | 业务定制 |
| KM匹配 | 自研引擎 | 核心竞争力 |

### 2.5 云服务选型

| 服务 | 推荐方案 | 备选方案 |
|------|---------|---------|
| 云厂商 | AWS | 阿里云/腾讯云 |
| 容器编排 | EKS (Kubernetes) | ECS Fargate |
| 数据库 | RDS PostgreSQL | 自建PostgreSQL |
| 缓存 | ElastiCache Redis | 自建Redis Cluster |
| 消息队列 | MSK (Kafka) | SQS/SNS |
| CDN | CloudFront | 阿里CDN |
| 监控 | Datadog | Prometheus + Grafana |
| 日志 | CloudWatch Logs | ELK Stack |

---

## 三、核心模块设计

### 3.1 匹配引擎（Matching Engine）

匹配引擎是Finda的核心，采用**脉冲式批量处理**架构。

#### 3.1.1 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                    Matching Engine                          │
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │ Candidate   │───▶│  Filter     │───▶│  Scoring    │    │
│  │ Pool        │    │  Pipeline   │    │  Engine     │    │
│  └─────────────┘    └─────────────┘    └──────┬──────┘    │
│                                                │            │
│                     ┌──────────────────────────┘            │
│                     ▼                                       │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │ KM Matcher  │───▶│  Result     │───▶│  Push       │    │
│  │ (最优匹配)  │    │  Aggregator │    │  Queue      │    │
│  └─────────────┘    └─────────────┘    └─────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

#### 3.1.2 过滤流水线

```python
class FilterPipeline:
    """三级漏斗过滤"""
    
    def filter(self, user: User, candidates: List[User]) -> List[User]:
        # 第一层：Geo-Time Grid
        candidates = self.geo_time_filter(user, candidates)
        # 第二层：向量相似度
        candidates = self.vector_similarity_filter(user, candidates)
        # 第三层：稀缺性分配
        candidates = self.scarcity_distribution(user, candidates)
        return candidates
    
    def geo_time_filter(self, user, candidates):
        """同城 + 时间窗口重叠"""
        return [
            c for c in candidates
            if c.city == user.city
            and time_overlap(c.available_slots, user.available_slots) > 0
        ]
    
    def vector_similarity_filter(self, user, candidates):
        """Embedding快速筛选Top K"""
        user_vec = get_embedding(user.preferences)
        scores = [cosine_similarity(user_vec, c.profile_vec) for c in candidates]
        return top_k(candidates, scores, k=50)
    
    def scarcity_distribution(self, user, candidates):
        """稀缺性动态分配"""
        # S级用户限制曝光，普通用户加权
        return redistribute_by_elo(candidates, user.elo)
```

#### 3.1.3 KM匹配算法集成

```python
class KMMatcher:
    """二分图最大权匹配"""
    
    def match(self, male_pool: List[User], female_pool: List[User]) -> List[Match]:
        """
        构建完全二分图，使用KM算法求最大权匹配
        
        权重计算：
        Match_Score = α·Sim(Pref_A, Attr_B) + β·Sim(Pref_B, Attr_A) 
                    + γ·TimeLoc_Score + δ·Elo_Balance
        """
        n, m = len(male_pool), len(female_pool)
        weight_matrix = self.build_weight_matrix(male_pool, female_pool)
        
        # KM算法求解
        matches = self.kuhn_munkres(weight_matrix)
        
        return [
            Match(male_pool[i], female_pool[j], weight_matrix[i][j])
            for i, j in matches
            if weight_matrix[i][j] > THRESHOLD
        ]
    
    def build_weight_matrix(self, males, females):
        """构建权重矩阵 O(n*m)"""
        return [
            [self.compute_match_score(m, f) for f in females]
            for m in males
        ]
```

### 3.2 用户系统（User Service）

#### 3.2.1 数据模型

```sql
-- 用户主表
CREATE TABLE users (
    id UUID PRIMARY KEY,
    phone VARCHAR(20) UNIQUE NOT NULL,
    nickname VARCHAR(50),
    gender VARCHAR(10),
    birthday DATE,
    
    -- 颜值评分
    elo_rating DECIMAL(5,2) DEFAULT 1200.00,
    photo_verified BOOLEAN DEFAULT FALSE,
    
    -- 信用评分
    credit_score DECIMAL(5,2) DEFAULT 100.00,
    
    -- 隐私设置
    privacy_level VARCHAR(20) DEFAULT 'standard', -- dark_pool/standard/public
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 用户画像表
CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    
    -- 向量嵌入
    preference_embedding VECTOR(1536),
    profile_embedding VECTOR(1536),
    
    -- JSONB灵活存储
    preferences JSONB,  -- 约会目的、偏好类型
    attributes JSONB,   -- 职业、学历、爱好
    
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 时间可用性表
CREATE TABLE user_availability (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'available', -- available/matched/expired
    
    INDEX idx_user_time (user_id, start_time, end_time),
    INDEX idx_time_status (start_time, status)
);

-- 诚意金账户表
CREATE TABLE earnest_accounts (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    balance DECIMAL(10,2) DEFAULT 0.00,
    frozen_amount DECIMAL(10,2) DEFAULT 0.00,
    
    updated_at TIMESTAMP DEFAULT NOW()
);
```

#### 3.2.2 ELO评分系统

```python
class ELOEngine:
    """ELO评分引擎"""
    
    BASE_RATING = 1200
    K_FACTOR = 32
    
    def update_after_match(self, user_a: User, user_b: User, outcome: MatchOutcome):
        """
        约会后更新ELO
        
        outcome: 
        - 双向奔赴: 双方小幅提升
        - 单向拒绝: 被拒绝方下降
        - 爽约: 爽约方大幅下降
        """
        if outcome == MatchOutcome.MUTUAL:
            # 双向奔赴，双方小幅提升
            self._update(user_a, user_b, 1, 0.5)
            self._update(user_b, user_a, 1, 0.5)
        elif outcome == MatchOutcome.REJECTED_BY_B:
            # A被B拒绝
            self._update(user_a, user_b, 0, 1)
        elif outcome == MatchOutcome.FLAKED_BY_A:
            # A爽约
            user_a.elo_rating -= 100  # 大幅惩罚
            
    def _update(self, user, opponent, actual_score, expected_modifier):
        expected = 1 / (1 + 10 ** ((opponent.elo_rating - user.elo_rating) / 400))
        user.elo_rating += self.K_FACTOR * (actual_score - expected)
```

### 3.3 支付系统（Payment Service）

#### 3.3.1 诚意金流程

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   用户A     │     │  支付服务   │     │   用户B     │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       │  1. 质押诚意金    │                   │
       │──────────────────▶│                   │
       │                   │                   │
       │                   │  2. 锁定金额      │
       │                   │──────────────────▶│
       │                   │                   │
       │                   │  3. 用户B确认     │
       │                   │◀──────────────────│
       │                   │                   │
       │  [见面成功]        │                   │
       │──────────────────▶│                   │
       │                   │  4. 双向退还       │
       │◀──────────────────│──────────────────▶│
       │                   │                   │
       │  [A爽约]           │                   │
       │──────────────────▶│                   │
       │                   │  5. A的诚意金赔付B  │
       │                   │──────────────────▶│
       │                   │                   │
```

#### 3.3.2 数据模型

```sql
-- 诚意金流水表
CREATE TABLE earnest_transactions (
    id UUID PRIMARY KEY,
    match_id UUID REFERENCES matches(id),
    user_id UUID REFERENCES users(id),
    
    amount DECIMAL(10,2) NOT NULL,
    type VARCHAR(20) NOT NULL, -- deposit/release/forfeit/compensate
    
    status VARCHAR(20) DEFAULT 'pending', -- pending/completed/failed
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- 匹配记录表
CREATE TABLE matches (
    id UUID PRIMARY KEY,
    user_a_id UUID REFERENCES users(id),
    user_b_id UUID REFERENCES users(id),
    
    match_score DECIMAL(5,2),
    
    status VARCHAR(20) DEFAULT 'pending', -- pending/locked/matched/completed/flaked
    
    scheduled_time TIMESTAMP,
    scheduled_location GEOGRAPHY(POINT, 4326),
    
    created_at TIMESTAMP DEFAULT NOW(),
    expired_at TIMESTAMP
);
```

### 3.4 消息系统（Message Service）

#### 3.4.1 设计原则

- **匹配前**：无消息通道（暗池模式）
- **匹配后**：限时聊天窗口（如24小时）
- **见面后**：聊天永久保留

#### 3.4.2 技术实现

```python
class MessageService:
    """消息服务"""
    
    async def send_message(self, match_id: str, sender_id: str, content: str):
        """发送消息"""
        match = await self.get_match(match_id)
        
        # 验证匹配状态
        if match.status != MatchStatus.MATCHED:
            raise PermissionError("匹配未完成，无法发送消息")
        
        # 验证时间窗口
        if match.is_expired():
            raise PermissionError("聊天窗口已过期")
        
        # 存储消息
        message = await self.store_message(match_id, sender_id, content)
        
        # WebSocket推送
        await self.websocket_push(match.get_other_user(sender_id), message)
```

#### 3.4.3 数据模型

```sql
-- 消息表
CREATE TABLE messages (
    id UUID PRIMARY KEY,
    match_id UUID REFERENCES matches(id),
    sender_id UUID REFERENCES users(id),
    
    content TEXT NOT NULL,
    type VARCHAR(20) DEFAULT 'text', -- text/image/location
    
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_match_messages ON messages(match_id, created_at);
```

### 3.5 信用系统（Credit Service）

#### 3.5.1 信用评分维度

| 维度 | 权重 | 说明 |
|------|------|------|
| 履约率 | 40% | 实际见面/匹配次数 |
| 准时率 | 20% | 迟到/爽约次数 |
| 评价质量 | 20% | 被评价分数 |
| 账号完整度 | 10% | 认证、照片等 |
| 活跃度 | 10% | 登录频率、响应速度 |

#### 3.5.2 信用影响

```python
class CreditImpact:
    """信用分影响机制"""
    
    IMPACT_MAP = {
        'complete_match': +2,      # 成功见面
        'mutual_like': +1,         # 双向喜欢
        'on_time': +1,             # 准时赴约
        'late_15min': -5,          # 迟到15分钟
        'flake': -30,              # 爽约
        'fake_photo': -50,         # 照片造假
        'harassment_report': -100, # 骚扰举报
    }
    
    def apply_impact(self, user_id: str, event: str):
        impact = self.IMPACT_MAP.get(event, 0)
        # 更新信用分，带衰减
        self.update_credit_with_decay(user_id, impact)
```

---

## 四、可扩展性设计

### 4.1 水平扩展策略

#### 4.1.1 无状态服务

所有服务设计为无状态，支持K8s HPA自动扩缩容：

```yaml
# Kubernetes HPA配置示例
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: matching-engine
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: matching-engine
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

#### 4.1.2 数据库分片

按城市分片，支持地域扩展：

```sql
-- 用户表按城市分片
shard_key: city_code

-- 分片规则
北京: shard_0
上海: shard_1
广州: shard_2
深圳: shard_3
其他: shard_default
```

### 4.2 缓存策略

#### 4.2.1 多级缓存

```
请求 → CDN缓存 → Redis缓存 → 数据库
         ↓           ↓
      静态资源    热点数据
```

#### 4.2.2 缓存预热

```python
class CacheWarmup:
    """缓存预热策略"""
    
    async def warmup_daily_matching(self):
        """每日匹配前预热"""
        # 1. 预加载活跃用户画像
        active_users = await self.get_active_users()
        for user in active_users:
            await self.cache_user_profile(user)
        
        # 2. 预计算向量索引
        await self.precompute_vector_index()
        
        # 3. 预加载地理索引
        await self.preload_geo_index()
```

### 4.3 异步处理架构

```python
# 使用Celery/Kafka进行异步处理
@app.task
def process_matching_batch():
    """批次匹配任务"""
    # 1. 获取待匹配用户
    pending_users = get_pending_users()
    
    # 2. 运行匹配算法
    matches = run_km_matching(pending_users)
    
    # 3. 推送结果
    for match in matches:
        send_match_notification.delay(match.id)

# 定时调度
@app.on_after_configure.connect
def setup_periodic_tasks(sender, **kwargs):
    # 每小时运行一次匹配
    sender.add_periodic_task(3600.0, process_matching_batch.s())
```

---

## 五、安全架构

### 5.1 数据安全

#### 5.1.1 敏感数据加密

| 数据类型 | 加密方式 | 说明 |
|---------|---------|------|
| 密码 | bcrypt | 单向哈希 |
| 手机号 | AES-256-GCM | 可逆加密 |
| 聊天记录 | AES-256-GCM | 端到端加密 |
| 地理位置 | 模糊化存储 | 精度降至街区级 |

#### 5.1.2 数据隔离

```sql
-- 用户数据按隐私级别隔离
CREATE TABLE user_data_dark_pool (
    -- 暗池用户数据，严格隔离
    user_id UUID PRIMARY KEY,
    -- 只有匹配成功后才能解锁
    encrypted_data BYTEA
);

CREATE TABLE user_data_standard (
    -- 标准用户数据
    user_id UUID PRIMARY KEY,
    -- 部分脱敏展示
    public_profile JSONB
);
```

### 5.2 API安全

#### 5.2.1 认证授权

```python
# JWT认证
class AuthService:
    def generate_token(self, user_id: str) -> str:
        payload = {
            'user_id': user_id,
            'exp': datetime.utcnow() + timedelta(hours=24),
            'iat': datetime.utcnow(),
            'scope': self.get_user_scope(user_id)
        }
        return jwt.encode(payload, SECRET_KEY, algorithm='HS256')
    
    def verify_token(self, token: str) -> dict:
        try:
            return jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        except jwt.ExpiredSignatureError:
            raise AuthError('Token expired')
```

#### 5.2.2 限流策略

```python
# API限流配置
RATE_LIMITS = {
    'match_request': '10/hour',     # 每小时最多10次匹配请求
    'message_send': '100/hour',     # 每小时最多100条消息
    'profile_view': '50/hour',      # 每小时最多查看50个profile
}
```

### 5.3 内容安全

#### 5.3.1 图像审核流水线

```
用户上传照片
    ↓
┌─────────────────────────────────────┐
│         图像审核流水线               │
│                                      │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐
│  │ 图片鉴黄│──▶│人脸检测 │──▶│活体检测 │
│  └─────────┘   └─────────┘   └─────────┘
│       ↓             ↓             ↓
│    过滤色情      确保真人      防止假照
│                                      │
│  ┌─────────┐   ┌─────────┐          │
│  │颜值评分 │──▶│特征提取 │          │
│  └─────────┘   └─────────┘          │
│       ↓             ↓                │
│    ELO输入      推荐特征             │
└─────────────────────────────────────┘
    ↓
存储通过审核的照片
```

#### 5.3.2 敏感词过滤

```python
class ContentModeration:
    """内容审核"""
    
    SENSITIVE_WORDS = load_sensitive_words()
    
    def check_text(self, text: str) -> bool:
        """检查敏感词"""
        for word in self.SENSITIVE_WORDS:
            if word in text:
                return False
        return True
    
    def moderate_intent(self, intent: dict) -> dict:
        """审核意图解析结果"""
        # 过滤不合规意图
        if intent.get('purpose') in ['illegal_purpose']:
            raise ContentError('不合规意图')
        
        # 脱敏敏感信息
        if intent.get('budget'):
            intent['budget'] = self.redact_budget(intent['budget'])
        
        return intent
```

### 5.4 隐私保护

#### 5.4.1 暗池交易机制

```python
class DarkPoolMatching:
    """暗池匹配"""
    
    async def match_dark_pool_users(self, user: User):
        """
        高隐私用户匹配流程：
        1. 不公开任何Profile
        2. AI后台匹配
        3. 双向确认后才解锁信息
        """
        # 查找暗池用户
        candidates = await self.find_dark_pool_candidates(user)
        
        # 匿名匹配
        match = await self.anonymous_match(user, candidates)
        
        if match:
            # 发送匿名匹配通知
            await self.notify_anonymous_match(user, match.other_user)
            
            # 等待双方确认
            confirmed = await self.wait_for_mutual_confirm(match)
            
            if confirmed:
                # 解锁双方信息
                await self.unlock_profiles(match)
```

#### 5.4.2 数据生命周期

```python
class DataLifecycle:
    """数据生命周期管理"""
    
    RETENTION_POLICY = {
        'match_records': 365,      # 匹配记录保留1年
        'messages': 90,           # 消息保留90天
        'location_data': 7,       # 位置数据保留7天
        'search_history': 30,      # 搜索历史30天
    }
    
    async def cleanup_expired_data(self):
        """定期清理过期数据"""
        for data_type, days in self.RETENTION_POLICY.items():
            await self.delete_older_than(data_type, days)
```

---

## 六、监控与运维

### 6.1 监控指标

#### 6.1.1 核心业务指标

| 指标 | 目标 | 告警阈值 |
|------|------|---------|
| 匹配成功率 | >60% | <40% |
| 用户响应率 | >50% | <30% |
| 见面履约率 | >80% | <60% |
| 日活用户匹配比 | >30% | <20% |

#### 6.1.2 技术指标

| 指标 | 目标 | 告警阈值 |
|------|------|---------|
| API响应时间 | <200ms | >500ms |
| 匹配算法耗时 | <30s | >60s |
| 数据库查询时间 | <50ms | >200ms |
| 消息推送延迟 | <3s | >10s |

### 6.2 日志架构

```yaml
# 日志收集架构
Fluentd/Fluent Bit:
  - 收集应用日志
  - 收集Nginx日志
  - 收集系统日志

Kafka:
  - 日志流传输
  - 削峰缓冲

ClickHouse:
  - 日志存储
  - 实时分析

Grafana:
  - 可视化
  - 告警面板
```

---

## 七、风险与应对

### 7.1 技术风险

| 风险 | 影响 | 概率 | 应对措施 |
|------|------|------|---------|
| KM算法性能瓶颈 | 高 | 中 | 1. 预筛选减少候选集<br>2. 分布式计算<br>3. 增量匹配 |
| 高并发推送压力 | 高 | 高 | 1. 消息队列削峰<br>2. 批量推送<br>3. 降级策略 |
| AI服务不稳定 | 高 | 中 | 1. 多供应商备份<br>2. 本地缓存<br>3. 降级方案 |
| 数据库主从延迟 | 中 | 中 | 1. 读写分离策略<br>2. 强一致场景用主库<br>3. 监控告警 |

### 7.2 业务风险

| 风险 | 影响 | 概率 | 应对措施 |
|------|------|------|---------|
| 冷启动用户不足 | 高 | 高 | 1. 种子用户计划<br>2. 托儿过渡策略<br>3. 区域聚焦 |
| 女性用户流失 | 高 | 高 | 1. 体验优化<br>2. 安全机制<br>3. 激励措施 |
| 用户信任危机 | 高 | 中 | 1. 透明运营<br>2. 快速响应<br>3. 用户教育 |
| 爽约率过高 | 高 | 中 | 1. 诚意金机制<br>2. 信用体系<br>3. 惩罚机制 |

### 7.3 合规风险

| 风险 | 影响 | 概率 | 应对措施 |
|------|------|------|---------|
| 个人信息保护法违规 | 高 | 中 | 1. 隐私设计<br>2. 数据最小化<br>3. 法务审核 |
| 内容监管 | 高 | 低 | 1. 实名认证<br>2. 内容审核<br>3. 敏感词过滤 |
| 支付合规 | 中 | 低 | 1. 牌照合作<br>2. 资金托管<br>3. 合规审计 |

### 7.4 运维风险

| 风险 | 影响 | 概率 | 应对措施 |
|------|------|------|---------|
| 单点故障 | 高 | 低 | 1. 多AZ部署<br>2. 自动故障转移<br>3. 定期演练 |
| 数据丢失 | 高 | 低 | 1. 多副本存储<br>2. 异地备份<br>3. 定期恢复测试 |
| DDoS攻击 | 高 | 中 | 1. CDN防护<br>2. 限流策略<br>3. 应急预案 |

---

## 八、成本估算

### 8.1 MVP阶段（3个月）

| 资源 | 月成本 | 说明 |
|------|--------|------|
| 云服务器 | ¥5,000 | 2台ECS |
| 数据库 | ¥2,000 | RDS PostgreSQL |
| Redis | ¥500 | ElastiCache |
| AI API调用 | ¥10,000 | LLM+Embedding |
| CDN+存储 | ¥1,000 | OSS+CDN |
| 监控+日志 | ¥1,000 | Datadog基础版 |
| **合计** | **¥19,500/月** | MVP期 |

### 8.2 增长期（1年后）

| 资源 | 月成本 | 说明 |
|------|--------|------|
| 云服务器 | ¥30,000 | K8s集群 |
| 数据库 | ¥15,000 | 分片集群 |
| Redis | ¥5,000 | 集群版 |
| AI API调用 | ¥100,000 | 大规模调用 |
| CDN+存储 | ¥10,000 | 图片+视频 |
| 监控+日志 | ¥5,000 | 企业版 |
| **合计** | **¥165,000/月** | 增长期 |

---

## 九、总结

Finda的技术架构以**匹配效率**为核心目标，采用：

1. **脉冲式批量处理**替代实时推送，实现全局最优匹配
2. **KM算法**保证系统总满意度最大化
3. **诚意金+信用体系**解决爽约问题
4. **暗池模式**保护高隐私用户
5. **分层架构**保证可扩展性

核心创新点：
- 时间维度熔断机制
- 唯一推送的稀缺性设计
- AI意图解析替代表单
- 博弈论防鸽机制

---

*文档版本：V1.0*
*最后更新：2026年4月6日*