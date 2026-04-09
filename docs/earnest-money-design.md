# Finda 诚意金机制设计文档

> 基于博弈论的防鸽与信任建立系统

## 1. 核心问题

### 1.1 约会市场的"爽约"问题
- **数据**: 传统约会软件爽约率高达 30-50%
- **原因**: 
  - 违约成本为0（临时有事就不来）
  - 选择太多（反正还有下一个）
  - 不够认真（只是试试看）

### 1.2 诚意金的博弈论原理
引入**承诺机制（Commitment Device）**：
- 事前支付小额资金作为"抵押"
- 顺利履约 → 全额退还（或转化为奖励）
- 爽约 → 抵押金赔付给对方

**效果**: 瞬间筛选掉 90% 的"口嗨党"和"临时党"

## 2. 诚意金系统设计

### 2.1 核心参数

```python
class EarnestMoneyConfig:
    """
    诚意金配置
    """
    # 基础金额（可根据场景调整）
    BASE_AMOUNT = 50  # 元
    
    # 场景系数
    SCENE_MULTIPLIERS = {
        "coffee": 0.6,      # 咖啡：30元
        "lunch": 1.0,       # 午餐：50元
        "dinner": 1.5,      # 晚餐：75元
        "fancy_dinner": 3.0 # 高档餐厅：150元
    }
    
    # 用户等级系数（信用越好，金额越低）
    CREDIT_MULTIPLIERS = {
        "new_user": 1.5,      # 新用户：1.5倍
        "normal": 1.0,        # 普通：标准
        "good": 0.8,          # 良好：8折
        "excellent": 0.5,     # 优秀：5折
        "vip": 0.3            # VIP：3折
    }
    
    # 最大/最小限制
    MIN_AMOUNT = 20   # 最低20元
    MAX_AMOUNT = 200  # 最高200元
    
    # 分配比例
    SPLIT_RATIO = {
        "to_victim": 0.7,     # 70%赔付给守约方
        "to_platform": 0.2,   # 20%平台手续费
        "to_charity": 0.1     # 10%捐赠公益（可选，提升品牌形象）
    }
```

### 2.2 金额计算公式

```python
def calculate_earnest_money(
    user_id: str,
    date_scene: str,
    restaurant_budget: int
) -> int:
    """
    计算诚意金金额
    
    公式: 诚意金 = BASE × 场景系数 × 信用系数
    """
    user = get_user(user_id)
    credit_level = user.credit_level  # new_user/normal/good/excellent/vip
    
    base = EarnestMoneyConfig.BASE_AMOUNT
    scene_mult = EarnestMoneyConfig.SCENE_MULTIPLIERS.get(date_scene, 1.0)
    credit_mult = EarnestMoneyConfig.CREDIT_MULTIPLIERS.get(credit_level, 1.0)
    
    amount = base * scene_mult * credit_mult
    
    # 根据餐厅预算调整（预算越高，诚意金越高）
    if restaurant_budget > 500:
        amount *= 1.5  # 人均500+的餐厅，诚意金1.5倍
    elif restaurant_budget > 300:
        amount *= 1.2
    
    # 限制范围
    amount = max(EarnestMoneyConfig.MIN_AMOUNT, 
                 min(EarnestMoneyConfig.MAX_AMOUNT, amount))
    
    return int(amount)
```

### 2.3 金额示例

| 用户类型 | 场景 | 餐厅预算 | 计算 | 诚意金 |
|---------|------|---------|------|--------|
| 新用户 | 晚餐 | 200/人 | 50×1.5×1.5 | 113元 |
| 普通用户 | 午餐 | 100/人 | 50×1.0×1.0 | 50元 |
| 优秀用户 | 晚餐 | 300/人 | 50×1.5×0.5×1.2 | 45元 |
| VIP用户 | 咖啡 | 50/人 | 50×0.6×0.3 | 20元（最低） |

## 3. 资金流转流程

### 3.1 状态机

```
                    ┌───────────────┐
                    │   订单创建     │
                    │ (Order Created)│
                    └───────┬───────┘
                            │ 支付诚意金
                            ▼
                    ┌───────────────┐
                    │   资金托管     │
                    │  (In Escrow)  │
                    └───────┬───────┘
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
        ┌─────────┐  ┌──────────┐  ┌──────────┐
        │ 顺利履约 │  │ 一方爽约  │  │ 双方取消  │
        │(Success)│  │ (No-show)│  │ (Cancel) │
        └────┬────┘  └────┬─────┘  └────┬─────┘
             │            │             │
             ▼            ▼             ▼
        ┌─────────┐  ┌──────────┐  ┌──────────┐
        │全额退还 │  │ 爽约方赔付 │  │ 双方退还 │
        │+信用加分│  │ 守约方获益 │  │ 信用不变 │
        └─────────┘  └──────────┘  └──────────┘
```

### 3.2 详细流程

#### 场景1: 顺利履约（Happy Path）

```python
def process_successful_date(date_id: str):
    """
    顺利履约处理
    """
    date_record = get_date(date_id)
    user_a, user_b = date_record.users
    
    # 1. 验证双方到达（地理围栏）
    verify_check_in(user_a, date_record.location)
    verify_check_in(user_b, date_record.location)
    
    # 2. 确认用餐完成（双方确认或AI验证）
    confirm_completion(user_a, user_b)
    
    # 3. 资金退还
    with transaction():
        refund(user_a, date_record.earnest_money_a)
        refund(user_b, date_record.earnest_money_b)
    
    # 4. 信用加分
    add_credit_score(user_a, 10)
    add_credit_score(user_b, 10)
    
    # 5. 解锁评价
    enable_mutual_review(user_a, user_b)
    
    # 6. 成就记录
    record_achievement(user_a, "守约达人")
    record_achievement(user_b, "守约达人")
```

#### 场景2: 一方爽约（惩罚机制）

```python
def process_no_show(date_id: str, no_show_user: str):
    """
    爽约处理
    """
    date_record = get_date(date_id)
    victim = date_record.get_other_user(no_show_user)
    
    # 1. 确认爽约（到达超时 + 联系不上）
    confirm_no_show(no_show_user)
    
    # 2. 计算赔付金额
    no_show_amount = date_record.earnest_money[no_show_user]
    victim_amount = date_record.earnest_money[victim]
    
    # 3. 资金分配
    with transaction():
        # 爽约方的诚意金分配
        to_victim = no_show_amount * 0.7
        to_platform = no_show_amount * 0.2
        to_charity = no_show_amount * 0.1
        
        transfer(no_show_user, victim, to_victim, "爽约赔付")
        transfer(no_show_user, PLATFORM, to_platform, "平台手续费")
        transfer(no_show_user, CHARITY, to_charity, "公益捐赠")
        
        # 守约方退还
        refund(victim, victim_amount)
    
    # 4. 信用惩罚
    deduct_credit_score(no_show_user, 50)
    add_credit_score(victim, 5)  # 安慰加分
    
    # 5. 标记爽约记录
    record_no_show(no_show_user, date_id)
    
    # 6. 通知
    send_notification(no_show_user, "您已爽约，诚意金已赔付给对方")
    send_notification(victim, f"对方爽约，您已获得{to_victim}元赔付")
    
    # 7. 限制（爽约3次禁号）
    if get_no_show_count(no_show_user) >= 3:
        ban_user(no_show_user, duration=timedelta(days=30))
```

#### 场景3: 双方协商取消（和平分手）

```python
def process_mutual_cancellation(date_id: str, reason: str):
    """
    双方协商取消
    """
    date_record = get_date(date_id)
    user_a, user_b = date_record.users
    
    # 1. 双方确认取消
    confirm_cancellation(user_a, user_b)
    
    # 2. 退还诚意金（全额）
    with transaction():
        refund(user_a, date_record.earnest_money_a)
        refund(user_b, date_record.earnest_money_b)
    
    # 3. 信用不变（因为是协商）
    # 但记录原因用于分析
    record_cancellation_reason(date_id, reason)
    
    # 4. 通知
    send_notification(user_a, "约会已取消，诚意金已退还")
    send_notification(user_b, "约会已取消，诚意金已退还")
```

## 4. 防作弊机制

### 4.1 爽约判定标准

```python
NO_SHOW_CRITERIA = {
    # 到达时间窗口（约会开始前15分钟到开始后30分钟）
    "arrival_window": {
        "before": timedelta(minutes=15),
        "after": timedelta(minutes=30)
    },
    
    # 验证方式（至少满足2项）
    "verification_methods": [
        "gps_geofencing",      # GPS地理围栏
        "restaurant_qr_check", # 餐厅扫码确认
        "ai_photo_verification", # AI拍照验证（双方合影）
        "mutual_confirmation"  # 双方确认
    ],
    
    # 联系判定（联系不上）
    "unreachable": {
        "call_attempts": 3,      # 尝试拨打3次
        "message_unread": True,   # 消息未读
        "app_inactive": timedelta(minutes=30)  # 30分钟不活跃
    }
}

def is_no_show(user_id: str, date_id: str) -> bool:
    """
    判定是否爽约
    """
    date_record = get_date(date_id)
    
    # 检查是否在到达窗口内
    now = datetime.now()
    arrival_deadline = date_record.scheduled_time + NO_SHOW_CRITERIA["arrival_window"]["after"]
    
    if now < arrival_deadline:
        return False  # 还在允许时间内
    
    # 检查验证方式（至少满足2项）
    verified_methods = 0
    
    if check_gps_geofencing(user_id, date_record.location):
        verified_methods += 1
    
    if check_restaurant_qr(user_id, date_record.restaurant):
        verified_methods += 1
    
    if check_mutual_confirmation(user_id, date_record.other_user):
        verified_methods += 1
    
    if verified_methods >= 2:
        return False  # 已验证到达
    
    # 检查是否联系不上
    if is_unreachable(user_id):
        return True  # 爽约！
    
    return False
```

### 4.2 防"骗赔付"机制

```python
def detect_fraud_pattern(user_id: str) -> bool:
    """
    检测欺诈模式（故意骗赔付）
    """
    user = get_user(user_id)
    
    # 模式1: 频繁被取消
    if user.dates_cancelled_by_others > 5 and user.total_dates < 10:
        # 90%的约会都被对方取消，可能是故意制造爽约
        return True
    
    # 模式2: 短时间内多次被爽约
    recent_no_shows = get_recent_no_shows(user_id, days=30)
    if len(recent_no_shows) >= 3:
        # 30天内被爽约3次+，可能是"碰瓷"
        return True
    
    # 模式3: 账户关联（检测小号）
    if has_linked_accounts(user_id):
        linked = get_linked_accounts(user_id)
        for acc in linked:
            if acc.has_no_show_record:
                # 关联账户有爽约记录
                return True
    
    # 模式4: 行为异常
    if user.average_response_time < timedelta(seconds=10):
        # 响应太快（可能是机器人）
        return True
    
    return False
```

## 5. 用户体验设计

### 5.1 支付流程

```
用户选择约会场景
      │
      ▼
┌─────────────┐
│ 显示诚意金   │  "为确保双方认真赴约，
│ 金额及说明   │   需支付诚意金￥50"
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 说明资金用途 │  "顺利见面 → 全额退还"
│ 和退还规则   │  "临时爽约 → 赔付给对方"
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   支付确认   │  微信支付/支付宝
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 支付成功     │  "诚意金已托管，开始匹配"
│ 进入撮合流程 │
└─────────────┘
```

### 5.2 退还通知

```python
SUCCESS_REFUND_TEMPLATE = {
    "title": "🎉 约会顺利完成！",
    "body": "诚意金￥{amount}已退还至您的账户",
    "details": {
        "date_time": "2026-04-10 19:00",
        "partner": "nickname",
        "restaurant": "餐厅名称",
        "refund_amount": 50,
        "credit_earned": 10
    },
    "cta": "查看评价"
}

NO_SHOW_COMPENSATION_TEMPLATE = {
    "title": "😔 对方爽约，您已获得赔付",
    "body": "对方诚意金￥{amount}已赔付给您",
    "details": {
        "scheduled_time": "2026-04-10 19:00",
        "no_show_user": "nickname",
        "compensation": 35,  # 70% of 50
        "platform_fee": 10,   # 20%
        "charity_donation": 5  # 10%
    },
    "cta": "继续寻找搭子"
}
```

## 6. 经济模型

### 6.1 平台收入

```python
# 平台收入来源
PLATFORM_REVENUE = {
    # 1. 爽约手续费（主要收入）
    "no_show_fee": "爽约金额的20%",
    
    # 2. VIP会员（减免诚意金）
    "vip_subscription": {
        "monthly": 29,
        "quarterly": 79,
        "yearly": 299
    },
    
    # 3. 增值服务
    "value_added_services": {
        "urgent_matching": 10,      # 加急匹配
        "premium_placement": 20,    # 优先展示
        "background_check": 50,     # 深度背景调查
    }
}

# 收入预测（假设）
REVENUE_PROJECTION = {
    "daily_active_dates": 1000,      # 每日成功约会
    "no_show_rate": 0.10,             # 10%爽约率
    "average_no_show_amount": 50,     # 平均爽约金额
    
    "daily_no_show_revenue": 1000 * 0.10 * 50 * 0.20,  # = 1000元/天
    "monthly_revenue": 1000 * 30,  # = 3万元/月（仅爽约费）
}
```

### 6.2 成本分析

```python
PLATFORM_COSTS = {
    # 1. 支付通道费（微信/支付宝）
    "payment_gateway_fee": 0.006,  # 0.6%
    
    # 2. 资金托管成本
    "escrow_cost": "银行托管费或第三方支付托管",
    
    # 3. 赔付垫资（风险）
    "compensation_reserve": "需准备一定流动资金用于即时赔付"
}
```

## 7. 法律合规

### 7.1 资金监管

```python
# 方案1: 第三方支付托管
THIRD_PARTY_ESCROW = {
    "provider": "支付宝/微信支付分",
    "model": "冻结-解冻模式",
    "advantage": "合规、用户信任度高",
    "cost": "0.6%手续费"
}

# 方案2: 银行监管账户
BANK_ESCROW = {
    "account_type": "专用监管账户",
    "requirement": "企业资质、金融牌照",
    "advantage": "完全合规",
    "cost": "账户管理费"
}

# 方案3: 虚拟积分（规避资金风险）
VIRTUAL_CREDIT = {
    "model": "用户充值积分，用积分支付",
    "advantage": "不涉及直接资金托管",
    "disadvantage": "用户感知弱，效果打折"
}
```

### 7.2 用户协议要点

```markdown
# 诚意金服务协议（摘要）

1. 诚意金性质
   - 诚意金是用户为表达约会诚意而支付的资金托管
   - 资金由平台/第三方托管，不归平台所有

2. 退还规则
   - 双方顺利见面 → 全额退还
   - 一方爽约 → 爽约方诚意金赔付给守约方
   - 双方协商取消 → 全额退还

3. 爽约定义
   - 约会时间开始后30分钟未到达
   - 联系不上（电话不接、消息不回）
   - 未提前2小时告知取消

4. 争议处理
   - 双方对是否爽约有争议时，由平台介入调查
   - 平台有权根据GPS、餐厅记录等判定

5. 禁止行为
   - 恶意制造爽约骗取赔付
   - 使用小号串通骗赔
   - 违者封号并追究法律责任
```

## 8. 实施优先级

### 🔴 P0 - MVP必须
1. **基础诚意金支付** (50元固定金额)
2. **资金托管** (微信支付分/支付宝)
3. **顺利履约退还** (原路退回)
4. **爽约判定** (GPS + 双方确认)

### 🟡 P1 - 体验优化
5. **动态金额** (根据场景调整)
6. **信用减免** (老用户优惠)
7. **赔付分成** (70/20/10模式)
8. **防作弊检测**

### 🟢 P2 - 高级功能
9. **VIP免诚意金** (会员权益)
10. **保险机制** (保险公司承保)
11. **分期支付** (大额诚意金)
12. **企业认证** (公司担保)

---

**文档版本**: v1.0  
**最后更新**: 2026-04-09  
**作者**: AI Assistant
