# Finda 撮合算法设计文档

> 基于订单簿撮合 + 稳定匹配算法的双向确认机制

## 1. 核心问题定义

### 1.1 传统约会软件的问题
- **异步非对称**: A喜欢B，B可能根本看不到A
- **选择困难**: 无限滑动，永远觉得"下一个更好"
- **效率低下**: 匹配成功率 < 5%

### 1.2 Finda 的解决方案
- **每日1人**: 强制减少选择，提高决策质量
- **双向确认**: 只有互相高度匹配才推送
- **批次撮合**: 全局最优匹配，而非局部随机

## 2. 系统架构

### 2.1 整体流程

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  用户发布    │────▶│  订单簿      │────▶│  撮合引擎    │
│  约会需求    │     │  (Order Book)│     │  (Matching) │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                                │
                       ┌────────────────────────┘
                       ▼
              ┌─────────────────┐
              │   每日1人推送    │
              │  (Daily Match)  │
              └────────┬────────┘
                       │
         ┌─────────────┼─────────────┐
         ▼             ▼             ▼
    ┌─────────┐  ┌─────────┐  ┌─────────┐
    │ 用户A   │  │ 用户B   │  │ 用户C   │
    │接收推送 │  │接收推送 │  │接收推送 │
    └────┬────┘  └────┬────┘  └────┬────┘
         │            │            │
         └────────────┼────────────┘
                      ▼
              ┌───────────────┐
              │   双向确认     │
              │ (Mutual Yes)  │
              └───────┬───────┘
                      ▼
              ┌───────────────┐
              │   约会锁定     │
              │ (Date Locked) │
              └───────────────┘
```

### 2.2 关键数据结构

```python
# 约会订单 (Order)
class DateOrder:
    user_id: str              # 用户ID
    intent: DateIntent        # 约会意图
    constraints: Constraints  # 约束条件
    created_at: datetime      # 创建时间
    status: OrderStatus       # 订单状态
    
class DateIntent:
    # 吃什么
    cuisine_type: List[str]   # ["火锅", "日料", "西餐"]
    # 何时
    date_time: datetime       # 2026-04-10 19:00
    time_flexibility: int     # 分钟，可接受的时间偏差
    # 预算
    budget_type: str          # "AA" | "我请客" | "对方请"
    budget_amount: int        # 人均预算（元）
    # 目的
    purpose: str              # "长期恋爱" | "短期约会" | "纯吃饭"
    
class Constraints:
    age_range: Tuple[int, int]     # (25, 35)
    gender_preference: str         # "男" | "女" | "不限"
    location: GeoPoint             # 地理位置
    location_radius: int           # 可接受的距离（米）
    identity_preference: List[str] # ["公务员", "教师"] 或 null
    
class OrderStatus:
    PENDING = "pending"      # 等待撮合
    MATCHED = "matched"      # 已匹配，等待确认
    CONFIRMED = "confirmed"  # 双向确认
    EXPIRED = "expired"      # 过期未匹配
    CANCELLED = "cancelled"  # 用户取消
```

## 3. 撮合算法详解

### 3.1 匹配分数计算

```python
def calculate_match_score(order_a: DateOrder, order_b: DateOrder) -> float:
    """
    计算两个订单的匹配分数 (0-100)
    """
    scores = []
    weights = []
    
    # 1. 时间匹配度 (权重: 30%)
    time_score = calculate_time_match(
        order_a.intent.date_time,
        order_b.intent.date_time,
        order_a.intent.time_flexibility,
        order_b.intent.time_flexibility
    )
    scores.append(time_score)
    weights.append(0.30)
    
    # 2. 地点匹配度 (权重: 25%)
    location_score = calculate_location_match(
        order_a.constraints.location,
        order_b.constraints.location,
        order_a.constraints.location_radius,
        order_b.constraints.location_radius
    )
    scores.append(location_score)
    weights.append(0.25)
    
    # 3. 餐饮偏好匹配度 (权重: 20%)
    cuisine_score = calculate_cuisine_match(
        order_a.intent.cuisine_type,
        order_b.intent.cuisine_type
    )
    scores.append(cuisine_score)
    weights.append(0.20)
    
    # 4. 预算匹配度 (权重: 15%)
    budget_score = calculate_budget_match(
        order_a.intent.budget_type,
        order_a.intent.budget_amount,
        order_b.intent.budget_type,
        order_b.intent.budget_amount
    )
    scores.append(budget_score)
    weights.append(0.15)
    
    # 5. 目的匹配度 (权重: 10%)
    purpose_score = calculate_purpose_match(
        order_a.intent.purpose,
        order_b.intent.purpose
    )
    scores.append(purpose_score)
    weights.append(0.10)
    
    # 加权平均
    final_score = sum(s * w for s, w in zip(scores, weights))
    return final_score

# 各维度匹配计算
def calculate_time_match(t1, t2, flex1, flex2) -> float:
    """
    时间匹配度计算
    示例: A想今晚7点，B想今晚7点半，双方flexibility都是30分钟 → 匹配
    """
    time_diff = abs((t1 - t2).total_seconds()) / 60  # 分钟差
    max_flex = max(flex1, flex2)
    
    if time_diff <= min(flex1, flex2):
        return 100  # 完美匹配
    elif time_diff <= max_flex:
        return 100 - (time_diff - min(flex1, flex2)) / (max_flex - min(flex1, flex2)) * 50
    else:
        return max(0, 100 - (time_diff - max_flex) / 10)

def calculate_location_match(loc1, loc2, radius1, radius2) -> float:
    """
    地点匹配度计算
    使用球面距离计算
    """
    distance = haversine_distance(loc1, loc2)  # 米
    max_radius = max(radius1, radius2)
    
    if distance <= min(radius1, radius2):
        return 100
    elif distance <= max_radius:
        return 100 - (distance - min(radius1, radius2)) / (max_radius - min(radius1, radius2)) * 50
    else:
        return max(0, 100 - (distance - max_radius) / 100)

def calculate_cuisine_match(cuisines1, cuisines2) -> float:
    """
    餐饮偏好匹配
    使用Jaccard相似度
    """
    set1 = set(cuisines1)
    set2 = set(cuisines2)
    intersection = len(set1 & set2)
    union = len(set1 | set2)
    
    if union == 0:
        return 50  # 都没指定，中性
    return (intersection / union) * 100

def calculate_budget_match(type1, amount1, type2, amount2) -> float:
    """
    预算匹配度
    """
    # 如果一方请客，另一方AA，需要协调
    if type1 == "我请客" and type2 == "我请客":
        return 100  # 都大方，完美
    elif type1 == "AA" and type2 == "AA":
        return 100  # 都AA，完美
    elif (type1 == "我请客" and type2 == "对方请") or \
         (type1 == "对方请" and type2 == "我请客"):
        return 100  # 互补，完美
    else:
        return 60  # 需要协调

def calculate_purpose_match(purpose1, purpose2) -> float:
    """
    目的匹配度
    长期恋爱 vs 短期约会 不匹配
    """
    purpose_compatibility = {
        ("长期恋爱", "长期恋爱"): 100,
        ("短期约会", "短期约会"): 100,
        ("纯吃饭", "纯吃饭"): 100,
        ("长期恋爱", "短期约会"): 20,
        ("短期约会", "长期恋爱"): 20,
        ("长期恋爱", "纯吃饭"): 60,
        ("纯吃饭", "长期恋爱"): 60,
        ("短期约会", "纯吃饭"): 70,
        ("纯吃饭", "短期约会"): 70,
    }
    return purpose_compatibility.get((purpose1, purpose2), 50)
```

### 3.2 全局撮合算法 (改进的Gale-Shapley)

```python
def global_matching_algorithm(orders: List[DateOrder]) -> Dict[str, str]:
    """
    全局撮合算法
    目标：最大化总体匹配分数，同时保证稳定性
    
    返回: {user_id: matched_user_id} 的映射
    """
    n = len(orders)
    if n < 2:
        return {}
    
    # 构建匹配分数矩阵
    score_matrix = [[0] * n for _ in range(n)]
    for i in range(n):
        for j in range(i + 1, n):
            score = calculate_match_score(orders[i], orders[j])
            score_matrix[i][j] = score
            score_matrix[j][i] = score
    
    # 使用匈牙利算法或贪心算法求解最大权匹配
    # 这里使用简化的贪心+稳定匹配
    matches = {}
    unmatched = set(range(n))
    
    # 按匹配分数降序排序所有可能的配对
    possible_pairs = []
    for i in range(n):
        for j in range(i + 1, n):
            possible_pairs.append((score_matrix[i][j], i, j))
    
    possible_pairs.sort(reverse=True)  # 高分在前
    
    # 贪心选择（确保每个人最多匹配一次）
    for score, i, j in possible_pairs:
        if i in unmatched and j in unmatched and score >= 70:  # 阈值70分
            matches[orders[i].user_id] = orders[j].user_id
            matches[orders[j].user_id] = orders[i].user_id
            unmatched.remove(i)
            unmatched.remove(j)
    
    return matches
```

### 3.3 每日1人选择算法

```python
def select_daily_match(user_id: str, candidates: List[DateOrder]) -> Optional[DateOrder]:
    """
    为用户选择今日最佳匹配
    
    策略：
    1. 计算与所有候选人的匹配分数
    2. 选择匹配分数最高且 >= 80分的
    3. 如果没有 >= 80分的，选择 >= 70分且历史评价最好的
    4. 如果都没有，今日无匹配
    """
    user_order = get_user_order(user_id)
    
    scored_candidates = []
    for candidate in candidates:
        score = calculate_match_score(user_order, candidate)
        credit = get_user_credit_score(candidate.user_id)  # 信用分
        scored_candidates.append((score, credit, candidate))
    
    # 按匹配分数降序排序
    scored_candidates.sort(key=lambda x: (x[0], x[1]), reverse=True)
    
    # 选择策略
    for score, credit, candidate in scored_candidates:
        if score >= 80:
            return candidate  # 优秀匹配
    
    for score, credit, candidate in scored_candidates:
        if score >= 70 and credit >= 80:
            return candidate  # 良好匹配 + 高信用
    
    return None  # 今日无合适匹配
```

## 4. 批次撮合流程

### 4.1 定时任务设计

```python
# 撮合脉冲（The Pulse）
# 每天运行3次：早上10点、下午3点、晚上7点

MATCHING_SCHEDULE = {
    "morning": "10:00",   # 匹配午餐/下午
    "afternoon": "15:00", # 匹配晚餐
    "evening": "19:00",   # 匹配夜宵/次日
}

def daily_matching_pulse():
    """
    每日撮合脉冲
    """
    # 1. 获取所有活跃的约会订单
    active_orders = get_active_orders(
        created_within=timedelta(hours=24),
        status=OrderStatus.PENDING
    )
    
    # 2. 按地理位置分区（避免跨城匹配）
    geo_groups = group_by_geography(active_orders, radius_km=10)
    
    # 3. 对每个区域运行撮合算法
    all_matches = {}
    for geo_group in geo_groups:
        matches = global_matching_algorithm(geo_group)
        all_matches.update(matches)
    
    # 4. 为每个用户选择每日1人
    daily_recommendations = {}
    for user_id in all_matches:
        if user_id not in daily_recommendations:
            match_id = all_matches[user_id]
            daily_recommendations[user_id] = match_id
            daily_recommendations[match_id] = user_id
    
    # 5. 发送推送通知
    for user_id, match_id in daily_recommendations.items():
        send_match_notification(user_id, match_id)
    
    # 6. 更新订单状态
    update_orders_to_matched(daily_recommendations)
```

### 4.2 并发控制（解决"A选C、B选E"问题）

```python
# 使用分布式锁防止并发问题

@redis_lock(key="matching_pulse", timeout=300)
def run_matching_pulse():
    """
    带锁的撮合流程，确保同一时间只有一个实例运行
    """
    daily_matching_pulse()

# 双向确认的原子性操作
def confirm_match(user_id: str, match_id: str) -> bool:
    """
    用户确认匹配
    使用Redis原子操作确保一致性
    """
    key = f"match:{min(user_id, match_id)}:{max(user_id, match_id)}"
    
    with redis.pipeline() as pipe:
        pipe.multi()
        pipe.hset(key, user_id, "confirmed")
        pipe.hget(key, match_id)
        results = pipe.execute()
        
        other_confirmed = results[1]
        
        if other_confirmed == b"confirmed":
            # 双向确认成功！
            finalize_match(user_id, match_id)
            return True
        else:
            # 等待对方确认
            return False
```

## 5. 用户可见的推送逻辑

### 5.1 推送内容设计

```python
def generate_match_notification(user_id: str, match_id: str) -> dict:
    """
    生成匹配推送内容
    """
    match_order = get_order(match_id)
    match_score = calculate_match_score(get_order(user_id), match_order)
    
    # AI推荐理由
    reasons = generate_ai_reasons(user_id, match_id)
    
    return {
        "title": "AI月老为你找到一位搭子！",
        "body": f"{match_order.user.nickname} 也想今晚吃{match_order.intent.cuisine_type[0]}",
        "data": {
            "match_id": match_id,
            "match_score": match_score,
            "reasons": reasons,
            "expiry": "24小时内有效"
        },
        "reasons": [
            "🎯 饮食偏好高度匹配",
            "📍 距离你仅2公里", 
            "⏰ 时间完美契合",
            "💎 对方诚意金已支付"
        ]
    }

def generate_ai_reasons(user_id: str, match_id: str) -> List[str]:
    """
    生成AI推荐理由（解释为什么推荐这个人）
    """
    user = get_user(user_id)
    match = get_user(match_id)
    
    reasons = []
    
    # 饮食偏好
    common_cuisines = set(user.preferences.cuisines) & set(match.preferences.cuisines)
    if common_cuisines:
        reasons.append(f"你们都喜欢{list(common_cuisines)[0]}")
    
    # 时间
    if abs(user.order.time - match.order.time) <= 30:
        reasons.append("时间安排完美契合")
    
    # 距离
    distance = calculate_distance(user.location, match.location)
    if distance <= 2000:
        reasons.append(f"距离仅{distance/1000:.1f}公里")
    
    # 信用
    if match.credit_score >= 90:
        reasons.append("对方信用优秀，约会记录良好")
    
    return reasons
```

### 5.2 倒计时机制

```python
class MatchExpiryManager:
    """
    匹配过期管理
    """
    MATCH_VALIDITY = timedelta(hours=24)  # 24小时有效
    
    def __init__(self):
        self.redis = redis_client
    
    def set_match_expiry(self, match_pair: Tuple[str, str]):
        """
        设置匹配过期时间
        """
        key = f"match_expiry:{min(match_pair)}:{max(match_pair)}"
        self.redis.setex(key, self.MATCH_VALIDITY, "active")
        
        # 注册过期回调（使用Redis Keyspace Notifications或定时任务）
        schedule_expiry_callback(match_pair, self.MATCH_VALIDITY)
    
    def on_match_expired(self, match_pair: Tuple[str, str]):
        """
        匹配过期处理
        """
        user_a, user_b = match_pair
        
        # 检查是否已确认
        if not is_mutually_confirmed(user_a, user_b):
            # 更新状态为过期
            update_match_status(user_a, user_b, MatchStatus.EXPIRED)
            
            # 通知双方
            send_expiry_notification(user_a, "缘分未到，明天会有更好的人选")
            send_expiry_notification(user_b, "缘分未到，明天会有更好的人选")
            
            # 记录到用户画像（用于优化未来匹配）
            record_missed_match(user_a, user_b)
```

## 6. 算法优化与冷启动

### 6.1 冷启动策略

```python
def handle_cold_start(user_id: str) -> List[DateOrder]:
    """
    新用户冷启动策略
    """
    user = get_user(user_id)
    
    # 策略1: 放宽匹配条件
    relaxed_constraints = relax_constraints(user.constraints, factor=1.5)
    
    # 策略2: 优先匹配高活跃用户
    active_candidates = get_highly_active_users(
        location=user.location,
        radius=user.constraints.location_radius * 2
    )
    
    # 策略3: 引入"托儿"（早期运营手段）
    if len(active_candidates) < 3 and is_early_stage():
        seed_users = get_seed_users()  # 运营安排的优质用户
        active_candidates.extend(seed_users)
    
    return active_candidates
```

### 6.2 持续学习

```python
def update_user_preferences(user_id: str, match_result: MatchResult):
    """
    根据匹配结果更新用户偏好模型
    """
    user = get_user(user_id)
    
    if match_result.outcome == "accepted":
        # 记录成功匹配的特征
        user.preference_model.positive_samples.append({
            "cuisine": match_result.cuisine,
            "time": match_result.time,
            "budget": match_result.budget,
            "location": match_result.location
        })
    elif match_result.outcome == "rejected":
        # 记录被拒绝的特征
        user.preference_model.negative_samples.append({
            "reason": match_result.rejection_reason,
            "features": extract_features(match_result)
        })
    
    # 重训练用户偏好模型（可以使用简单的协同过滤或向量相似度）
    retrain_preference_model(user_id)
```

## 7. 关键指标监控

```python
MATCHING_METRICS = {
    # 撮合成功率
    "match_success_rate": "成功撮合数 / 总订单数",
    
    # 双向确认率
    "mutual_confirmation_rate": "双向确认数 / 推送数",
    
    # 平均匹配分数
    "average_match_score": "所有成功匹配的分数平均值",
    
    # 撮合延迟
    "matching_latency": "从发布到匹配成功的平均时间",
    
    # 过期率
    "expiry_rate": "过期订单数 / 总订单数",
    
    # 冷启动成功率
    "cold_start_success_rate": "新用户首次匹配成功率",
}
```

---

## 8. 实现优先级

### 🔴 P0 - MVP必须
1. **基础匹配分数计算** (时间、地点、餐饮)
2. **每日1人推送** (简化版贪心算法)
3. **双向确认机制** (Redis原子操作)
4. **24小时过期机制**

### 🟡 P1 - 体验优化
5. **AI推荐理由生成**
6. **全局最优撮合** (匈牙利算法)
7. **地理分区优化**
8. **用户偏好学习**

### 🟢 P2 - 高级功能
9. **多批次撮合** (早/中/晚)
10. **冷启动策略**
11. **信用分加权**
12. **动态定价** (根据供需调整)

---

**文档版本**: v1.0  
**最后更新**: 2026-04-09  
**作者**: AI Assistant
