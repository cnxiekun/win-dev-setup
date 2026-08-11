---
name: agnes-vision
description: 图片理解/识别（国内版）— 当用户让你"看"图片、识别截图、描述图片内容、OCR 提取图片文字、分析图表截图时使用。用 Agnes 2.5 Flash 多模态模型读取图片内容，让不支持图片输入的主力模型（如 deepseek）也能理解图片。支持本地图片文件、截图和公开图片 URL。
---

# Agnes Vision 图片理解

> 基于官方文档：https://wiki.agnes-ai.cn/zh-Hans/docs/agnes-25-flash

## 概述

本 skill 用 **Agnes 2.5 Flash**（多模态对话模型）识别图片内容，把图片「翻译」成文字描述，供不支持图片输入的主力模型（如 deepseek-v4-flash）使用。相当于给主力模型配一只「看图的眼睛」。

## API 详情

- **Base URL**: `https://api.agnes-ai.cn`
- **Endpoint**: `POST https://api.agnes-ai.cn/v1/chat/completions`
- **Model**: `agnes-2.5-flash`
- **Auth**: `Authorization: Bearer YOUR_API_KEY`
- **Content-Type**: `application/json`

## 图片输入：两种方式都支持

| 图片形式 | 用法 | 适用场景 |
|---|---|---|
| **公开 URL** | `image_url.url` 直接放 URL | 图片已在线可访问 |
| **本地文件/base64** | 图片转成 `data:image/png;base64,...` 放进 `image_url.url` | **本地截图、本地图片文件**（实测可用） |

> **用户给本地图片/截图时，必须先转成 base64 data URI**，格式：
> `data:image/png;base64,<图片的 base64 编码>`
> 支持常见格式：png、jpg/jpeg、webp、gif。

## 请求结构（关键）

```json
{
  "model": "agnes-2.5-flash",
  "messages": [
    {
      "role": "user",
      "content": [
        {"type": "text", "text": "请详细描述这张图片的内容"},
        {"type": "image_url", "image_url": {"url": "<图片URL 或 data URI>"}}
      ]
    }
  ],
  "max_tokens": 2048,
  "chat_template_kwargs": {
    "enable_thinking": false
  }
}
```

## ⚠️ 关键配置：默认关掉 thinking（最重要）

**必须设置 `chat_template_kwargs.enable_thinking = false`**。原因（实测）：
- Agnes 2.5 Flash 默认开 Thinking 模式，会先消耗大量 token「思考」再回答
- 开 thinking：`max_tokens: 4096` 甚至 `8192` 都可能被思考吃光导致**回答为空**
- **关 thinking**：`max_tokens: 2048` 就够，输出直接是文字，稳定可靠（实测 24 tokens 出结果）

```json
"chat_template_kwargs": { "enable_thinking": false }
```

## 关于 max_tokens（备查）

- **默认 `2048`**（关 thinking 后足够，几乎不可能超）
- 上限 `65536`；超大需求（超长 OCR/描述）才需要 `16384` 以上
- 如果关掉 thinking 仍觉得输出被截断，优先提高 max_tokens 到 4096/8192

2. **回答取 `choices[].message.content`**
   响应里可能有 reasoning 字段（思考过程），最终回答在 `message.content`。
   用 Python 解析时：`d['choices'][0]['message']['content']`。

3. **`prompt_tokens` 里含 `image_tokens`**
   图片会消耗 tokens（一张 2K 图约 966 tokens），大图可能更多。响应正常即可，不用处理。

## 转换本地图片为 base64

用 Python（无需额外库）：

```bash
python -c "
import base64, json, sys, os
img_path = sys.argv[1]
with open(img_path, 'rb') as f:
    b64 = base64.b64encode(f.read()).decode()
ext = os.path.splitext(img_path)[1].lstrip('.').lower()
mime = {'png':'image/png','jpg':'image/jpeg','jpeg':'image/jpeg','webp':'image/webp','gif':'image/gif'}.get(ext, 'image/png')
uri = f'data:{mime};base64,{b64}'
print(uri)
" "图片路径.jpg"
```

## 请求示例

### 本地截图（base64）

```bash
python -c "
import base64, json, os
img = 'C:/Users/xxx/Desktop/截图.png'
b64 = base64.b64encode(open(img,'rb').read()).decode()
uri = f'data:image/png;base64,{b64}'
payload = {
  'model': 'agnes-2.5-flash',
  'messages': [{'role':'user','content':[
    {'type':'text','text':'请详细描述这张图片的内容'},
    {'type':'image_url','image_url':{'url':uri}}
  ]}],
  'max_tokens': 2048,
  'chat_template_kwargs': {'enable_thinking': False}
}
import urllib.request
req = urllib.request.Request('https://api.agnes-ai.cn/v1/chat/completions',
  data=json.dumps(payload).encode(),
  headers={'Authorization': 'Bearer YOUR_API_KEY', 'Content-Type': 'application/json'})
resp = json.load(urllib.request.urlopen(req, timeout=120))
print(resp['choices'][0]['message']['content'])
"
```

### 公开 URL

```bash
curl -s https://api.agnes-ai.cn/v1/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-2.5-flash",
    "messages": [{
      "role": "user",
      "content": [
        {"type": "text", "text": "请详细描述这张图片的内容"},
        {"type": "image_url", "image_url": {"url": "https://example.com/image.jpg"}}
      ]
    }],
    "max_tokens": 2048,
    "chat_template_kwargs": {"enable_thinking": false}
  }'
```

## 提示词最佳实践

根据用户意图选择 prompt 侧重：

- **看图描述**：「请详细描述这张图片的内容，包括主要元素、场景、风格和氛围」
- **OCR 提取文字**：「请提取图片中的所有文字内容，保持原文格式」
- **截图分析**（UI 截图）：「分析这个界面，描述主要 UI 元素、布局和可能的问题」
- **图表解读**：「解读这张图表，说明数据趋势和关键信息」
- **问答**：「根据图片回答问题：<用户的具体问题>」

## 使用流程

当用户要求查看/识别/理解图片时：

1. **获取图片**：确认图片来源
   - 本地路径/截图 → 先转 base64 data URI
   - URL → 直接用
2. **构造请求**：`agnes-2.5-flash` + 图片 + 合适的中文 prompt
3. **发请求**：调 chat completions，`max_tokens: 2048` + `enable_thinking: false`
4. **取结果**：`choices[].message.content`，把文字描述返回给用户/主力模型

> **重要**：识别出的图片内容应整合进当前对话上下文，让不支持图片的主力模型能基于这些文字继续理解任务。
