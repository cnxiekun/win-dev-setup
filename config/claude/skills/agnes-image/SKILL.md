---
name: agnes-image
description: Agnes 图像生成（国内版）— 使用 agnes-image-2.1-flash 生成或编辑图片。当用户要求生成图片、绘图、设计图、文生图、图生图、多图合成、图像编辑时使用。支持 1K/2K/3K/4K 尺寸档位、多图合成、URL/Base64 输出。
---

# Agnes Image 2.1 Flash 图像生成

> 基于官方文档：https://wiki.agnes-ai.cn/zh-Hans/docs/agnes-image-21-flash

## 概述

Agnes Image 2.1 Flash 是 Agnes AI 的升级图像生成模型，支持**文生图、图生图、多图合成**。针对高信息密度图像、复杂构图和细节丰富的视觉场景做了优化。

## API 详情

- **Base URL**: `https://api.agnes-ai.cn`
- **Endpoint**: `POST https://api.agnes-ai.cn/v1/images/generations`
- **Model**: `agnes-image-2.1-flash`
- **Auth**: `Authorization: Bearer YOUR_API_KEY`
- **Content-Type**: `application/json`

## 请求参数

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `model` | string | 是 | 固定 `agnes-image-2.1-flash` |
| `prompt` | string | 是 | 图像生成或编辑的文本指令 |
| `size` | string | 是 | 输出尺寸档位：`1K`、`2K`、`3K`、`4K`；兼容 `1024x768` 历史写法 |
| `ratio` | string | 否 | 宽高比：`1:1`、`3:4`、`4:3`、`16:9`、`9:16`、`2:3`、`3:2`、`21:9`，默认 `1:1` |
| `image` | string[] | 图生图/多图必填 | ⚠️ 放在 **`extra_body.image`**，不放在顶层 |
| `return_base64` | boolean | 否 | 文生图 Base64 输出时用 |
| `extra_body` | object | 否 | 高级参数容器 |
| `extra_body.response_format` | string | 否 | 输出格式：`url` 或 `b64_json` |

## 尺寸与宽高比

**推荐 `size` 档位 + `ratio` 组合**，可预期输出：

| Ratio | 1K | 2K | 3K | 4K |
|---|---|---|---|---|
| `1:1` | 1024x1024 | 2048x2048 | 3072x3072 | 4096x4096 |
| `16:9` | 1312x736 | 2624x1472 | 3936x2208 | 5248x2944 |
| `9:16` | 736x1312 | 1472x2624 | 2208x3936 | 2944x5248 |
| `3:4` | 864x1152 | 1728x2304 | 2592x3456 | 3456x4608 |
| `4:3` | 1152x864 | 2304x1728 | 3456x2592 | 4608x3456 |
| `2:3` | 832x1248 | 1664x2496 | 2496x3744 | 3328x4992 |
| `3:2` | 1248x832 | 2496x1664 | 3744x2496 | 4992x3328 |
| `21:9` | 1568x672 | 3136x1344 | 4704x2016 | 6272x2688 |

> 需要 `1920x1080` 这类显示器素材：请求 `size: "2K"` + `ratio: "16:9"`，下游再裁剪。

## 重要规则

1. **文生图**：`model` + `prompt` + `size` 必填。URL 输出无需额外配置；Base64 输出顶层加 `return_base64: true`。
2. **图生图**：输入图放 **`extra_body.image`** 数组（URL 或 Data URI Base64）。URL 输出设 `extra_body.response_format: "url"`；Base64 输出设 `"b64_json"`。
3. **多图合成**：多张参考图放 `extra_body.image` 数组。
4. **⚠️ 严禁**把 `response_format` 放顶层，也不要传 `tags: ["img2img"]`。
5. 非英文 prompt 先翻译成英文再发，保留视觉细节和约束。

## 示例

### 文生图（URL 输出）

```bash
curl https://api.agnes-ai.cn/v1/images/generations \
  -H "Authorization: Bearer $AGNES_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-image-2.1-flash",
    "prompt": "A luminous floating city above a misty canyon at sunrise, cinematic realism",
    "size": "2K",
    "ratio": "16:9",
    "extra_body": {
      "response_format": "url"
    }
  }'
```

### 文生图（Base64 输出）

```bash
curl https://api.agnes-ai.cn/v1/images/generations \
  -H "Authorization: Bearer $AGNES_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-image-2.1-flash",
    "prompt": "A clean product photo of a glass cube on a white studio background",
    "size": "1024x768",
    "return_base64": true
  }'
```

### 图生图（URL 输出）— image 在 extra_body

```bash
curl https://api.agnes-ai.cn/v1/images/generations \
  -H "Authorization: Bearer $AGNES_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-image-2.1-flash",
    "prompt": "Transform the scene into a rain-soaked cyberpunk night, preserve original composition",
    "size": "1024x768",
    "extra_body": {
      "image": ["https://example.com/input-image.png"],
      "response_format": "url"
    }
  }'
```

### 多图合成

```bash
curl https://api.agnes-ai.cn/v1/images/generations \
  -H "Authorization: Bearer $AGNES_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-image-2.1-flash",
    "prompt": "Combine the two characters into an intense fantasy battle scene",
    "size": "1024x768",
    "extra_body": {
      "image": [
        "https://example.com/character-1.png",
        "https://example.com/character-2.png"
      ],
      "response_format": "url"
    }
  }'
```

### 响应格式

URL 输出：`data[0].url`；Base64 输出：`data[0].b64_json`

```json
{
  "created": 1780000000,
  "data": [
    {
      "url": "https://storage.googleapis.com/agnes-aigc/xxx.png",
      "b64_json": null,
      "revised_prompt": null
    }
  ]
}
```

## 推荐提示词结构

- **文生图**：`[主体] + [场景/环境] + [风格] + [光照] + [构图] + [质量要求]`
- **图生图**：`[改变要求] + [新风格/场景] + [需添加/移除元素] + [需保留元素]`
- **多图合成**：`[每张图角色] + [目标场景] + [图之间关系] + [风格/光照/构图]`

## 使用流程

用户要求生成/创建/绘制/设计图片时：
1. 确认：清晰 prompt（描述图像内容）
2. 确认尺寸：档位（如 `2K`）+ 宽高比（如 `16:9`），或兼容写法 `1024x768`
3. 确认模式：文生图 / 图生图（需输入图 URL）/ 多图合成（需多张图 URL）
4. 确认输出：URL（默认）或 Base64
5. 构造并发送请求，非英文 prompt 先转英文
