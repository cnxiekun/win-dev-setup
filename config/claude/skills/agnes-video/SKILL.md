---
name: agnes-video
description: Agnes 视频生成（国内版）— 使用 agnes-video-v2.0 生成视频。当用户要求生成视频、动画、图生视频、关键帧动画时使用。支持文生视频、图生视频、关键帧动画，异步任务 + 轮询获取结果。
---

# Agnes Video V2.0 视频生成

> 基于官方文档：https://wiki.agnes-ai.cn/zh-Hans/docs/agnes-video-v20

## 概述

Agnes Video V2.0 是面向生产场景的视频生成模型，支持**文生视频、图生视频、关键帧动画**。采用**异步任务 API**：先创建任务，再通过 `video_id` 或 `task_id` 获取结果。

## API 详情

- **Base URL**: `https://api.agnes-ai.cn`
- **创建任务**: `POST https://api.agnes-ai.cn/v1/videos`
- **获取结果（推荐）**: `GET https://api.agnes-ai.cn/agnesapi?video_id=<VIDEO_ID>`
- **获取结果（旧版）**: `GET https://api.agnes-ai.cn/v1/videos/<TASK_ID>`
- **Model**: `agnes-video-v2.0`
- **Auth**: `Authorization: Bearer YOUR_API_KEY`
- **Content-Type**: `application/json`

## 创建任务参数

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `model` | string | 是 | 固定 `agnes-video-v2.0` |
| `prompt` | string | 是 | 视频内容文本描述 |
| `image` | string | 否 | 图生视频用，单张图片 URL |
| `mode` | string | 否 | 生成模式：`ti2vid` 或 `keyframes` |
| `height` | integer | 否 | 高度，默认 `768` |
| `width` | integer | 否 | 宽度，默认 `1152` |
| `num_frames` | integer | 否 | 帧数：`≤ 441` 且遵循 `8n + 1` |
| `frame_rate` | number | 否 | 帧率：`1–60` |
| `num_inference_steps` | integer | 否 | 推理步数 |
| `seed` | integer | 否 | 随机种子，可复现 |
| `negative_prompt` | string | 否 | 反向提示词，描述避免内容 |
| `extra_body.image` | array | 否 | 关键帧模式输入图 URL 数组 |
| `extra_body.mode` | string | 否 | 附加模式，如 `keyframes` |

## 尺寸标准化

模型支持三个标准分辨率档位：`480p`、`720p`、`1080p`。宽高比不符时会自动映射到最接近的标准输出。

- 常见宽高比：`16:9`（横版）、`9:16`（竖版短视频）、`1:1`（方形）、`4:3`、`3:4`
- 排查尺寸问题以响应中 `metadata.size_mapping` 为准

## 帧数规则

**`num_frames` ≤ 441 且必须遵循 `8n + 1`**（合法值：1, 9, 17, 25, ..., 441）。

| 目标时长 | 推荐参数 |
|---|---|
| 约 3 秒 | `num_frames: 81`, `frame_rate: 24` |
| 约 5 秒 | `num_frames: 121`, `frame_rate: 24` |
| 约 10 秒 | `num_frames: 241`, `frame_rate: 24` |
| 约 18 秒 | `num_frames: 441`, `frame_rate: 24` |

## 三种模式

1. **文生视频**（默认 `ti2vid`）：`model` + `prompt`，可选尺寸/帧数/帧率
2. **图生视频**：加 `image`（单张 URL）
3. **关键帧动画**：`extra_body.image` 数组 + `extra_body.mode: "keyframes"` + `prompt`

> 注意：图生视频用顶层 `image`；关键帧用 `extra_body.image`。

## 示例

### 文生视频

```bash
curl -X POST https://api.agnes-ai.cn/v1/videos \
  -H "Authorization: Bearer $AGNES_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-video-v2.0",
    "prompt": "A cinematic shot of a cat walking on the beach at sunset, soft ocean waves, warm golden lighting, realistic motion",
    "height": 768,
    "width": 1152,
    "num_frames": 121,
    "frame_rate": 24
  }'
```

### 图生视频

```bash
curl -X POST https://api.agnes-ai.cn/v1/videos \
  -H "Authorization: Bearer $AGNES_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-video-v2.0",
    "prompt": "The woman slowly turns around and looks back at the camera, natural facial expression",
    "image": "https://example.com/image.png",
    "num_frames": 121,
    "frame_rate": 24
  }'
```

### 关键帧动画

```bash
curl -X POST https://api.agnes-ai.cn/v1/videos \
  -H "Authorization: Bearer $AGNES_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-video-v2.0",
    "prompt": "Generate a smooth cinematic transition between the keyframes, maintaining visual consistency",
    "extra_body": {
      "image": [
        "https://example.com/keyframe1.png",
        "https://example.com/keyframe2.png"
      ],
      "mode": "keyframes"
    },
    "num_frames": 121,
    "frame_rate": 24
  }'
```

## 创建任务响应

```json
{
  "id": "task_YOUR_TASK_ID",
  "task_id": "task_YOUR_TASK_ID",
  "video_id": "video_YOUR_VIDEO_ID",
  "object": "video",
  "model": "agnes-video-v2.0",
  "status": "queued",
  "progress": 0,
  "created_at": 1780457477,
  "seconds": "10.0",
  "size": "1280x768"
}
```

> `video_id` 是推荐的获取结果标识；`task_id`/`id` 用于旧版查询。

## 获取视频结果（轮询）

```bash
curl --request GET 'https://api.agnes-ai.cn/agnesapi?video_id=<VIDEO_ID>' \
  --header 'Authorization: Bearer YOUR_API_KEY'
```

如需显式指定模型（非默认或上游原始 ID）：加 `&model_name=agnes-video-v2.0`。

## 获取结果响应

**任务完成后，视频 URL 在 `metadata.url`**。

```json
{
  "id": "task_YOUR_TASK_ID",
  "status": "completed",
  "progress": 100,
  "seconds": "10.0",
  "size": "1280x768",
  "metadata": {
    "url": "https://platform-outputs.agnes-ai.space/videos/agnes-video-v2.0/task_YOUR_TASK_ID.mp4",
    "size_mapping": {
      "adjusted": true,
      "resolution": "720p",
      "ratio": "16:9",
      "width": 1280,
      "height": 720
    }
  }
}
```

> ⚠️ 视频 URL 在 **`metadata.url`**，不在顶层。旧 skill 写的是顶层 `video_url/url`，会取不到结果。

## 任务状态

| 状态 | 说明 |
|---|---|
| `queued` | 队列等待中 |
| `in_progress` | 生成中 |
| `completed` | 成功，取 `metadata.url` |
| `failed` | 失败 |

## 推荐参数

- **标准视频**：`width: 1152`, `height: 768`, `num_frames: 121`, `frame_rate: 24`
- **社交短视频**：`num_frames: 81` 或 `121`, `frame_rate: 24`
- **可复现**：设置固定 `seed`
- **更流畅运动**：`frame_rate: 24` 或 `30`

## 提示词最佳实践

- **文生视频**：`[主体] + [动作] + [场景] + [镜头运动] + [光线] + [风格]`
- **图生视频**：描述哪些应运动、哪些关键元素保持稳定
- **关键帧动画**：描述帧间过渡关系，保持主体身份和镜头一致

## 使用流程

用户要求生成视频/动画时：
1. 收集：prompt、尺寸（宽×高，默认 1152×768）、帧数（`8n+1` 规则，默认 121）、帧率（默认 24）、模式（文/图/关键帧）
2. `POST /v1/videos` 创建任务，捕获 `video_id`
3. `GET /agnesapi?video_id=<VIDEO_ID>` 轮询直到 `completed`
4. 取 `metadata.url` 交付结果；非英文 prompt 先转英文
