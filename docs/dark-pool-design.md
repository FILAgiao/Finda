# Finda 暗池模式设计文档

> 隐私优先的撮合系统 —— 区别于传统社交软件的"大广场"模式

## 1. 核心问题

### 1.1 传统社交软件的隐私问题

**Tinder/探探模式（大广场模式）的问题**:
```
┌─────────────────────────────────────┐
│           公共广场                  │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐      │
│  │用户A│ │用户B│ │用户C│ │用户D│ ... │
│  │照片│ │照片│ │照片│ │照片│      │
│  │资料│ │资料│ │资料│ │资料│      │
│  └────┘ └────┘ └────┘ └────┘      │
│       所有人都能看到所有人         │
└─────────────────────────────────────┘

问题：
- 公务员/教师不敢用（怕被同事/学生看到）
- 照片被截图传播（无法删除）
- 前任/熟人尴尬相遇
- "视奸"严重（被前任/暗恋对象暗中观察）
```

### 1.2 Finda 的解决方案：暗池模式

```
┌─────────────────────────────────────┐
│           暗池 (Dark Pool)          │
│                                     │
│  用户A              用户B           │
│  ┌────┐            ┌────┐          │
│  │ ??? │  ←──AI──→ │ ??? │          │
│  │ ??? │   撮合     │ ??? │          │
│  └────┘            └────┘          │
│                                     │
│  特点：                             │
│  - 不在广场上展示                   │
│  - 只有AI能看到完整信息             │
│  - 匹配成功后双方才可见             │
└─────────────────────────────────────┘
```

**暗池模式的优势**:
- ✅ 保护隐私（公务员/教师敢用了）
- ✅ 无社交压力（不用担心被熟人看到）
- ✅ 专注匹配（基于意图而非外貌左滑）
- ✅ 减少"视奸"（无法浏览陌生人）

## 2. 系统架构

### 2.1 三层可见性模型

```python
class VisibilityLevel:
    """
    信息可见性层级
    """
    # Level 0: 仅自己和AI可见
    PRIVATE = 0
    
    # Level 1: 匹配成功后对匹配对象可见
    MATCHED = 1
    
    # Level 2: 约会完成后可见
    DATE_COMPLETED = 2
    
    # Level 3: 经过脱敏后可分享
    SHAREABLE = 3

class UserProfile:
    """
    用户信息分级
    """
    # Level 0: 仅自己和AI
    private_info = {
        "real_name": str,          # 真实姓名
        "phone": str,              # 手机号
        "id_number": str,          # 身份证号（认证用）
        "exact_address": str,      # 精确住址
        "workplace": str,          # 具体工作单位
        "photos": List[str],       # 高清照片
        "income": int,             # 收入
    }
    
    # Level 1: 匹配成功后可见
    matched_visible = {
        "nickname": str,           # 昵称
        "blurred_photo": str,      # 模糊照片
        "age": int,                # 年龄
        "occupation_type": str,    # 职业类型（公务员/教师等，不显示具体单位）
        "education": str,          # 学历
        "height": int,             # 身高
        "interests": List[str],    # 兴趣爱好
        "voice_intro": str,        # 语音介绍
    }
    
    # Level 2: 约会完成后可见
    post_date_visible = {
        "clear_photos": List[str], # 清晰照片
        "social_media": str,       # 社交媒体（可选）
        "detailed_bio": str,       # 详细介绍
    }
    
    # Level 3: 可分享（脱敏）
    shareable = {
        "date_story": str,         # 约会故事（脱敏）
        "match_card": str,         # 匹配卡片（精美图片）
    }
```

### 2.2 暗池撮合流程

```
┌──────────────┐
│   用户注册    │
│  填写完整资料 │
└──────┬───────┘
       │ 信息分级存储
       ▼
┌──────────────┐
│  Level 0      │
│  仅AI可见     │
│  完整信息     │
└──────┬───────┘
       │ 用户发布约会需求
       ▼
┌──────────────┐
│   AI撮合      │
│  基于意图匹配 │
│  不展示照片   │
└──────┬───────┘
       │ 匹配成功
       ▼
┌──────────────┐
│  Level 1      │
│  双方解锁     │
│  模糊照片+基础 │
└──────┬───────┘
       │ 双方确认见面
       ▼
┌──────────────┐
│   约会完成    │
│  地理围栏验证 │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Level 2      │
│  解锁清晰照片 │
│  完整资料     │
└──────┬───────┘
       │ 双方评价良好
       ▼
┌──────────────┐
│  Level 3      │
│  可分享卡片   │
│  约会故事     │
└──────────────┘
```

## 3. 信息展示策略

### 3.1 模糊照片算法

```python
def generate_blurred_photo(original_photo: str, blur_level: str = "medium") -> str:
    """
    生成模糊照片
    
    模糊程度：
    - light: 轻微模糊，能辨认大致轮廓和气质
    - medium: 中等模糊，能看出身材和发型
    - heavy: 重度模糊，只能看出性别和大概年龄段
    """
    from PIL import Image, ImageFilter
    
    img = Image.open(original_photo)
    
    blur_radius = {
        "light": 3,
        "medium": 8,
        "heavy": 15
    }.get(blur_level, 8)
    
    blurred = img.filter(ImageFilter.GaussianBlur(radius=blur_radius))
    
    # 添加水印（防止截图滥用）
    from PIL import ImageDraw, ImageFont
    draw = ImageDraw.Draw(blurred)
    
    # 半透明水印
    watermark = Image.new('RGBA', blurred.size, (255, 255, 255, 0))
    watermark_draw = ImageDraw.Draw(watermark)
    watermark_draw.text(
        (blurred.width//2, blurred.height//2),
        "Finda",
        fill=(255, 255, 255, 128),
        anchor="mm",
        font=ImageFont.load_default()
    )
    
    blurred = Image.alpha_composite(blurred.convert('RGBA'), watermark).convert('RGB')
    
    return save_photo(blurred)

# 渐进式清晰
PROGRESSIVE_REVEAL = {
    "initial_match": "heavy_blur",      # 刚匹配：重度模糊
    "both_confirmed": "medium_blur",    # 双方都确认：中度模糊
    "date_approaching": "light_blur",   # 约会临近：轻度模糊
    "date_completed": "clear"           # 约会完成：清晰照片
}
```

### 3.2 职业隐私保护

```python
def mask_occupation(real_occupation: str) -> str:
    """
    职业脱敏
    
    示例：
    - "XX市税务局公务员" → "公务员"
    - "XX中学高级教师" → "教师"
    - "XX银行支行行长" → "金融行业"
    """
    occupation_mapping = {
        # 公务员体系
        r".*税务.*": "公务员",
        r".*财政.*": "公务员",
        r".*法院.*": "公务员",
        r".*检察院.*": "公务员",
        r".*政府.*": "公务员",
        r".*街道办.*": "公务员",
        
        # 教师体系
        r".*小学.*": "小学教师",
        r".*中学.*": "中学教师",
        r".*高中.*": "高中教师",
        r".*大学.*": "高校教师",
        
        # 医疗
        r".*医院.*医生": "医生",
        r".*医院.*护士": "护士",
        
        # 金融
        r".*银行.*": "金融行业",
        r".*证券.*": "金融行业",
        r".*保险.*": "金融行业",
        
        # IT
        r".*程序员.*": "互联网",
        r".*工程师.*": "互联网",
        r".*产品经理.*": "互联网",
    }
    
    for pattern, masked in occupation_mapping.items():
        if re.match(pattern, real_occupation):
            return masked
    
    # 默认返回大类
    return "其他职业"

# 单位验证但不展示
def verify_but_hide_workplace(user_id: str, workplace: str) -> bool:
    """
    验证工作单位真实性，但不对外展示
    """
    # 验证方式：工牌照片、钉钉/企业微信验证、社保记录等
    is_verified = verify_workplace(user_id, workplace)
    
    if is_verified:
        # 只存储，不展示
        store_private_info(user_id, "workplace", workplace)
        return True
    return False
```

### 3.3 地理位置模糊

```python
from geopy.distance import geodesic
import random

def fuzzy_location(real_location: GeoPoint, radius: int = 500) -> GeoPoint:
    """
    地理位置模糊
    
    返回以真实位置为中心，半径500米内的随机点
    """
    # 随机角度
    angle = random.uniform(0, 360)
    # 随机距离（0到radius米）
    distance = random.uniform(0, radius)
    
    # 计算偏移后的坐标
    new_location = geodesic(meters=distance).destination(
        point=(real_location.lat, real_location.lng),
        bearing=angle
    )
    
    return GeoPoint(new_location.latitude, new_location.longitude)

# 距离显示模糊
def fuzzy_distance_display(real_distance_meters: int) -> str:
    """
    距离模糊显示
    
    - 0-500m: "附近"
    - 500-1000m: "1公里内"
    - 1-3km: "3公里内"
    - 3-5km: "5公里内"
    - >5km: 不显示距离
    """
    if real_distance_meters < 500:
        return "附近"
    elif real_distance_meters < 1000:
        return "1公里内"
    elif real_distance_meters < 3000:
        return "3公里内"
    elif real_distance_meters < 5000:
        return "5公里内"
    else:
        return "同城"
```

## 4. 防"视奸"机制

### 4.1 无浏览功能

```python
class NoBrowsePolicy:
    """
    禁止浏览陌生人
    """
    
    FORBIDDEN_ACTIONS = {
        # 传统社交软件的功能，Finda没有
        "swipe_cards": False,        # 没有左滑右滑
        "browse_profiles": False,    # 不能浏览陌生人资料
        "search_users": False,       # 不能搜索用户
        "view_nearby": False,        # 不能查看附近的人
        "see_fans": False,           # 不能看谁喜欢我
        "view_history": False,       # 不能查看访问记录
    }
    
    ONLY_WAYS_TO_CONNECT = {
        # 只能通过AI撮合
        "ai_match": True,            # AI主动推送
        "mutual_friend_intro": True, # 共同好友介绍（未来功能）
    }
```

### 4.2 截图防护

```python
SCREENSHOT_PROTECTION = {
    # 技术手段
    "technical": {
        "ios": "启用 iOS ScreenCapture 检测 API",
        "android": "启用 Android FLAG_SECURE 标志",
        "detection": "检测到截图后自动模糊关键信息",
    },
    
    # 法律手段
    "legal": {
        "watermark": "所有照片添加隐形水印（包含用户ID）",
        "terms_of_service": "用户协议明确禁止截图传播",
        "enforcement": "发现传播后封号并追究法律责任",
    },
    
    # 提示
    "reminder": {
        "on_enter": "进入App时提示：为保护隐私，请勿截图",
        "on_view_photo": "查看照片时浮层提示：截图会被记录",
    }
}
```

### 4.3 前任/熟人屏蔽

```python
class BlockSystem:
    """
    屏蔽系统
    """
    
    def block_phone_contacts(user_id: str):
        """
        自动屏蔽通讯录联系人
        """
        user = get_user(user_id)
        contacts = get_phone_contacts(user_id)  # 用户授权后读取
        
        for contact in contacts:
            if is_registered_user(contact.phone):
                create_block(user_id, contact.user_id, reason="phone_contact")
                create_block(contact.user_id, user_id, reason="phone_contact")
    
    def block_ex_partners(user_id: str):
        """
        屏蔽前任
        """
        ex_partners = get_date_history(user_id)
        
        for ex in ex_partners:
            if ex.status == "bad_breakup":  # 分手不愉快
                create_block(user_id, ex.user_id, reason="ex_partner")
                create_block(ex.user_id, user_id, reason="ex_partner")
    
    def manual_block(user_id: str, blocked_user_id: str):
        """
        手动屏蔽
        """
        create_block(user_id, blocked_user_id, reason="manual")
        
        # 可选：双向屏蔽
        if should_block_both_ways(user_id, blocked_user_id):
            create_block(blocked_user_id, user_id, reason="manual")
```

## 5. 匹配后的信息解锁

### 5.1 渐进式解锁

```python
class ProgressiveUnlock:
    """
    渐进式信息解锁
    """
    
    UNLOCK_STAGES = {
        "stage_1_matched": {
            "trigger": "系统判定匹配成功",
            "unlock": [
                "nickname",           # 昵称
                "blurred_photo_heavy", # 重度模糊照片
                "age",                # 年龄
                "gender",             # 性别
                "occupation_type",    # 职业大类
                "date_intent",        # 约会意图
            ],
            "duration": "24小时（匹配有效期）",
        },
        
        "stage_2_both_confirmed": {
            "trigger": "双方都点击'确认见面'",
            "unlock": [
                "blurred_photo_medium", # 中度模糊照片
                "voice_intro",          # 语音介绍
                "interests",            # 兴趣爱好
                "fuzzy_location",       # 模糊位置
            ],
            "duration": "直到约会完成",
        },
        
        "stage_3_date_approaching": {
            "trigger": "约会前2小时",
            "unlock": [
                "blurred_photo_light",  # 轻度模糊照片
                "contact_wechat",       # 微信号（可选）
                "exact_restaurant",     # 精确餐厅位置
            ],
            "duration": "约会当天",
        },
        
        "stage_4_date_completed": {
            "trigger": "约会完成（地理围栏验证）",
            "unlock": [
                "clear_photos",         # 清晰照片
                "detailed_bio",         # 详细介绍
                "social_media",         # 社交媒体（对方可选分享）
            ],
            "duration": "永久（如果对方不删除你）",
        },
    }
```

### 5.2 撤回与删除

```python
class DataControl:
    """
    用户数据控制权
    """
    
    def revoke_match(user_id: str, match_id: str):
        """
        撤回匹配
        """
        if can_revoke(user_id, match_id):
            # 删除双方的可见信息
            delete_match_data(user_id, match_id)
            
            # 通知对方
            notify(match_id, "对方已撤回匹配")
            
            # 退还诚意金（如果已支付）
            refund_earnest_money(user_id)
            refund_earnest_money(match_id)
    
    def delete_account(user_id: str):
        """
        删除账号
        """
        # GDPR/个人信息保护法合规
        delete_all_personal_data(user_id)
        
        # 通知所有有过匹配的用户
        for match in get_all_matches(user_id):
            notify(match, "该用户已删除账号")
        
        # 彻底删除
        permanent_delete(user_id)
```

## 6. 特殊用户保护

### 6.1 公务员/教师专属通道

```python
class VerifiedProfessionals:
    """
    职业认证用户特殊保护
    """
    
    VERIFIED_TYPES = ["公务员", "教师", "医生", "律师"]
    
    def enhanced_privacy(user_id: str):
        """
        增强隐私保护
        """
        user = get_user(user_id)
        
        if user.occupation_type in VERIFIED_TYPES:
            # 更严格的模糊
            set_blur_level(user_id, "heavy")
            
            # 不显示具体职业
            set_occupation_display(user_id, "认证职业")
            
            # 优先匹配同类
            set_match_preference(user_id, "same_profession", True)
            
            # 隐藏活跃状态
            set_online_status(user_id, "hidden")
    
    def profession_only_mode(user_id: str):
        """
        仅匹配认证用户模式
        """
        # 只和通过职业认证的用户匹配
        set_match_filter(user_id, "verified_only", True)
```

### 6.2 高管/名人保护

```python
class VIPProtection:
    """
    VIP用户保护
    """
    
    def vip_privacy(user_id: str):
        """
        VIP专属隐私保护
        """
        # 人工审核所有匹配
        set_manual_review(user_id, True)
        
        # 照片完全不展示，只展示AI生成的虚拟形象
        set_avatar_type(user_id, "ai_generated")
        
        # 专用客服
        assign_dedicated_support(user_id)
        
        # 优先匹配（减少等待）
        set_priority_matching(user_id, True)
```

## 7. 技术实现

### 7.1 数据隔离

```python
# 数据库设计
DATABASE_SCHEMA = {
    "users": {
        "user_id": "主键",
        "nickname": "昵称（Level 1）",
        "age": "年龄（Level 1）",
        # ... 其他Level 1字段
    },
    
    "user_private": {
        "user_id": "主键",
        "real_name": "真实姓名（Level 0）",
        "phone": "手机号（Level 0）",
        "id_number": "身份证号（Level 0）",
        "exact_address": "精确地址（Level 0）",
        "clear_photos": "清晰照片（Level 0）",
        # ... 其他Level 0字段
        "access_control": "JSON配置谁能看什么",
    },
    
    "user_access_log": {
        "log_id": "主键",
        "viewer_id": "查看者",
        "viewed_id": "被查看者",
        "data_type": "查看的数据类型",
        "timestamp": "时间戳",
        "ip_address": "IP地址",
    }
}

# API权限控制
class PrivacyMiddleware:
    """
    API中间件：检查数据访问权限
    """
    
    def check_access(self, viewer_id: str, viewed_id: str, data_type: str) -> bool:
        """
        检查是否有权限访问特定数据
        """
        # 1. 检查是否匹配
        if not is_matched(viewer_id, viewed_id):
            return False
        
        # 2. 检查解锁阶段
        unlock_stage = get_unlock_stage(viewer_id, viewed_id)
        allowed_data = UNLOCK_STAGES[unlock_stage]["unlock"]
        
        if data_type not in allowed_data:
            return False
        
        # 3. 记录访问日志
        log_access(viewer_id, viewed_id, data_type)
        
        return True
```

### 7.2 端到端加密（可选增强）

```python
# 对于聊天记录
class E2EEncryption:
    """
    端到端加密（可选功能）
    """
    
    def encrypt_message(self, sender_id: str, receiver_id: str, message: str) -> str:
        """
        加密消息
        """
        # 生成临时密钥对
        shared_secret = generate_shared_secret(sender_id, receiver_id)
        encrypted = aes_encrypt(message, shared_secret)
        return encrypted
    
    def decrypt_message(self, receiver_id: str, encrypted_message: str) -> str:
        """
        解密消息
        """
        shared_secret = retrieve_shared_secret(receiver_id)
        decrypted = aes_decrypt(encrypted_message, shared_secret)
        return decrypted
```

## 8. 用户体验平衡

### 8.1 隐私 vs 匹配效率

```python
PRIVACY_EFFICIENCY_TRADE_OFF = {
    # 完全隐私（匹配效率低）
    "maximum_privacy": {
        "photo": "AI生成虚拟形象",
        "occupation": "不展示",
        "location": "仅同城",
        "expected_matches": "每周1-2个",
    },
    
    # 平衡（推荐）
    "balanced": {
        "photo": "重度模糊",
        "occupation": "大类",
        "location": "模糊位置",
        "expected_matches": "每天1个",
    },
    
    # 开放（匹配效率高）
    "open": {
        "photo": "轻度模糊",
        "occupation": "具体职业",
        "location": "精确到区",
        "expected_matches": "每天3-5个",
    }
}
```

### 8.2 隐私设置向导

```python
def privacy_setup_wizard(user_id: str):
    """
    隐私设置向导
    """
    ask_user("您的工作性质是？", [
        ("公务员/教师/敏感职业", "maximum_privacy"),
        ("普通白领", "balanced"),
        ("自由职业/无所谓", "open"),
    ])
    
    ask_user("您最担心什么？", [
        ("被熟人看到", "enable_contact_blocking"),
        ("信息泄露", "enable_maximum_encryption"),
        ("前任纠缠", "enable_ex_blocking"),
    ])
```

## 9. 法律合规

### 9.1 隐私政策要点

```markdown
# Finda 隐私政策（摘要）

## 1. 信息收集
- 必要信息：手机号、昵称、约会意图
- 可选信息：照片、职业、兴趣爱好
- 敏感信息：真实姓名、身份证号（仅认证用，不展示）

## 2. 信息使用
- AI撮合：AI使用完整信息计算匹配度
- 匹配展示：仅展示模糊照片和脱敏信息
- 第三方：绝不向第三方出售或共享个人信息

## 3. 信息保护
- 加密存储：敏感信息加密存储
- 访问控制：严格限制内部人员访问权限
- 数据隔离：Level 0信息隔离存储

## 4. 用户权利
- 查看权：用户可随时查看自己的完整信息
- 更正权：用户可更正不准确的信息
- 删除权：用户可要求删除所有信息
- 撤回权：用户可随时撤回匹配

## 5. 特殊情况
- 法律要求：如法律要求，我们可能向执法机关提供信息
- 安全事件：发生数据泄露时，我们会在72小时内通知用户
```

### 9.2 合规检查清单

```python
COMPLIANCE_CHECKLIST = {
    "个人信息保护法": {
        "最小必要原则": "只收集必要信息",
        "明示同意": "用户明确同意隐私政策",
        "数据本地化": "中国大陆用户数据存储在国内",
        "删除权": "提供账号删除功能",
    },
    
    "GDPR（如有欧洲用户）": {
        "data_portability": "数据可携带权",
        "right_to_be_forgotten": "被遗忘权",
        "privacy_by_design": "默认隐私设计",
    },
    
    "网络安全法": {
        "实名认证": "手机号实名",
        "内容审核": "聊天内容AI审核",
        "日志留存": "访问日志留存6个月",
    }
}
```

## 10. 实施优先级

### 🔴 P0 - MVP必须
1. **基础信息分级** (Level 0/1)
2. **模糊照片** (重度模糊)
3. **职业脱敏** (大类展示)
4. **无浏览功能** (只有AI推送)

### 🟡 P1 - 体验优化
5. **渐进式解锁** (4阶段解锁)
6. **通讯录屏蔽** (自动屏蔽熟人)
7. **截图防护** (水印+检测)
8. **地理位置模糊** (500米随机)

### 🟢 P2 - 高级功能
9. **前任屏蔽** (基于约会历史)
10. **VIP专属保护** (人工审核)
11. **端到端加密** (聊天加密)
12. **AI虚拟形象** (完全不露脸)

---

**文档版本**: v1.0  
**最后更新**: 2026-04-09  
**作者**: AI Assistant
