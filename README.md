<!-- xCloudVLMui — README.md -->
<div align="center">

# xCloudVLMui Platform

**工廠設備健康管理平台 · 工廠視覺 AI 指揮台**

[![Platform](https://img.shields.io/badge/Platform-macOS%20%2F%20iPhone-000000?logo=apple&logoColor=white)]()
[![Python](https://img.shields.io/badge/Python-3.11-3776ab?logo=python&logoColor=white)]()
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110-009688?logo=fastapi&logoColor=white)]()
[![Next.js](https://img.shields.io/badge/Next.js-14-000000?logo=nextdotjs&logoColor=white)]()
[![YOLO](https://img.shields.io/badge/YOLO-v26n%20E2E-ff6600?logo=ultralytics&logoColor=white)]()
[![Docker](https://img.shields.io/badge/Docker-Compose%20v2-2496ED?logo=docker&logoColor=white)]()
[![License](https://img.shields.io/badge/License-Proprietary-red)]()

> 由 **云碩科技 xCloudinfo Corp.Limited** 開發  
> 本倉庫為 **macOS / Apple Silicon** 專用部署版本

</div>

---

## 🌐 四平台部署總覽

| 平台 | 倉庫 | 主要 Port | 架構 | 推論加速 |
|------|------|-----------|------|----------|
| **macOS** ← 本倉庫 | [xCloudVLMui](https://github.com/guessleej/xCloudVLMui) | `:3110` | ARM64 / x86 | Ollama (Apple Silicon) |
| **AIR-030 JetPack 6.0** | [xCloudVLMui-air030](https://github.com/guessleej/xCloudVLMui-air030) | `:8880` | ARM64 | CUDA 12.2 / TensorRT |
| **MIC-743 JetPack 7.1** | [xCloudVLMui-mic743](https://github.com/guessleej/xCloudVLMui-mic743) | `:8780` | ARM64 | CUDA 12.6 / TensorRT |
| **x86-64 通用** | [xCloudVLMui-x86](https://github.com/guessleej/xCloudVLMui-x86) | `:8680` | AMD64 | CPU / 可選 NVIDIA GPU |

---

---

## 目錄

- [產品概述](#產品概述)
- [系統架構](#系統架構)
- [資料流](#資料流)
- [YOLO 模型介紹](#yolo-模型介紹)
- [AI 模型介紹](#ai-模型介紹)
- [快速開始](#快速開始)
- [CI/CD 流程](#cicd-流程)
- [API 文件](#api-文件)
- [專案結構](#專案結構)

---

## 產品概述

**xCloudVLMui** 是一套執行於本地端（macOS / Jetson AGX Orin 64GB）的工廠視覺 AI 平台，結合：

| 能力 | 技術 | 說明 |
|------|------|------|
| 🔭 **視覺語言模型推論** | Gemma 4 E4B Q4_K_M | 128K context，30–50 tok/s，支援 iPhone 相機串流 |
| 🤖 **多模態 YOLO 偵測** | YOLO26n E2E + YOLO26n-Pose | 物件偵測 + 姿態估計 + SORT 多目標追蹤 |
| 📡 **MQTT 感應器整合** | Eclipse Mosquitto | 溫度/震動/壓力/轉速即時監控 |
| 🧠 **RAG 知識庫** | ChromaDB + nomic-embed-text | PDF/TXT/MD/CSV 文件語意問答 |
| 📊 **設備健康儀表板** | VHS 評分系統 | 四段式管線狀態、5S 評分、警報 CRUD |
| 🔐 **多方式認證** | Microsoft Entra ID / Google / GitHub OAuth | 支援本地管理員 |

### 四大視覺巡檢模式

| 模式 | YOLO 任務 | VLM 分析重點 |
|------|-----------|-------------|
| 🏭 **設備巡檢 Equipment** | 物件偵測（detect） | 設備外觀損傷、VHS 健康評分、5S 稽核 |
| 👷 **人員辨識 People** | 姿態估計（pose） | PPE 合規（安全帽/反光衣）、姿態異常、危險行為 |
| ⚡ **事件偵測 Events** | 偵測 + SORT 追蹤 | 入侵偵測、動線追蹤、危險物品即時警報 |
| 📦 **物品辨識 Objects** | 物件偵測（detect） | 物料清點、非法物品、環境雜亂評分 |

---

## 系統架構

```
┌─────────────────────────────────────────────────────────────────────┐
│                       使用者端 (macOS / iPhone)                       │
│                                                                       │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐   │
│  │  iPhone 相機  │    │  macOS 瀏覽器 │    │    Mobile Safari     │   │
│  │  (WebRTC)    │───▶│  Next.js 14  │◀───│   (PWA Support)      │   │
│  └──────────────┘    └──────┬───────┘    └──────────────────────┘   │
│                             │                                         │
│              ┌──────────────┼──────────────┐                         │
│              ▼              ▼              ▼                          │
│       YOLO26n E2E    YOLO26n-Pose    SORT Tracker                    │
│       (偵測/分類)    (姿態估計)     (IoU多目標追蹤)                   │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ HTTP / WebSocket
┌──────────────────────────────▼──────────────────────────────────────┐
│                        Nginx (Port 80/443)                            │
│                  反向代理 + SSL + 靜態資源服務                         │
└─────┬────────────────────────────────────────────────────┬──────────┘
      │ /api/*                                              │ /*
      ▼                                                     ▼
┌─────────────────┐                               ┌────────────────┐
│ FastAPI Backend │                               │ Next.js Static │
│   (Port 8000)   │                               │   (Port 3000)  │
│                 │                               └────────────────┘
│  Routers:       │
│  ├─ /api/auth          認證 & JWT            │
│  ├─ /api/vlm           VLM 推論 (WebSocket)  │
│  ├─ /api/vision        視覺 Session 儲存     │
│  ├─ /api/equipment     設備管理              │
│  ├─ /api/vhs           VHS 健康評分          │
│  ├─ /api/alerts        警報 CRUD             │
│  ├─ /api/mqtt          MQTT 設備資料         │
│  ├─ /api/knowledge     知識庫管理            │
│  ├─ /api/chat          RAG 對話              │
│  ├─ /api/pipeline      分析管線              │
│  ├─ /api/reports       報告生成              │
│  └─ /api/settings      系統設定             │
└────────┬────────────────────────────────────┘
         │
    ┌────┴─────────────────────────────────┐
    │           資料層 (Local Storage)      │
    │                                       │
    │  ┌─────────┐  ┌──────────┐  ┌──────┐│
    │  │ SQLite  │  │ ChromaDB │  │ MQTT ││
    │  │(主資料庫)│  │(向量資料庫)│  │Broker││
    │  └─────────┘  └──────────┘  └──────┘│
    └───────────────────────────────────────┘
         │
    ┌────┴─────────────────────────────────┐
    │        AI 推論服務                    │
    │                                       │
    │  ┌────────────────┐  ┌─────────────┐ │
    │  │  llama.cpp     │  │  VLM WebUI  │ │
    │  │ gemma4:e4b Q4  │  │  (可選)     │ │
    │  └────────────────┘  └─────────────┘ │
    └───────────────────────────────────────┘
```

### 容器服務一覽

| 服務名稱 | Image | Port | 職責 |
|---------|-------|------|------|
| `frontend` | node:20-alpine | 3000 | Next.js 14 UI + ONNX 推論 |
| `backend` | python:3.11-slim | 8000 | FastAPI REST + WebSocket |
| `nginx` | nginx:alpine | 80/443 | 反向代理 + SSL Termination |
| `mosquitto` | eclipse-mosquitto:2 | 1883/9001 | MQTT Broker |
| `vlm-webui` | (可選) | 8080 | VLM Web 介面 |

---

## 資料流

### 視覺巡檢分析流程

```
iPhone 相機 / macOS WebCam
        │
        │ getUserMedia (WebRTC)
        ▼
  ┌─────────────────────────────────────────────┐
  │           瀏覽器端即時處理 (60fps→10fps)       │
  │                                               │
  │  VideoElement → OffscreenCanvas               │
  │        │                                      │
  │        ├─ [People Mode] ──▶ useYoloPose        │
  │        │                   YOLO26n-pose.onnx   │
  │        │                   [1,300,57] E2E      │
  │        │                   → 17 COCO 關鍵點    │
  │        │                                      │
  │        ├─ [Events Mode] ──▶ useYolo             │
  │        │                   YOLO26n.onnx        │
  │        │                   [1,300,6] E2E       │
  │        │                   → SortTracker       │
  │        │                   → trackId 追蹤     │
  │        │                                      │
  │        └─ [Other Modes] ──▶ useYolo             │
  │                            80-class 偵測       │
  │                            製造業危險優先排序   │
  └───────────────────┬─────────────────────────┘
                      │ 抽幀 (每5秒 或 手動)
                      ▼ base64 JPEG + YOLO meta
  ┌─────────────────────────────────────────────┐
  │         WebSocket /api/vlm/stream            │
  │                                              │
  │  VLM Prompt (模式專屬 Expert-level)           │
  │  + YOLO 偵測結果注入 (class/conf/bbox)        │
  │        │                                     │
  │        ▼                                     │
  │  llama.cpp → gemma4:e4b Q4_K_M               │
  │  → 串流 token 輸出                           │
  │  → 解析: DETECT/ENV/VHS/5S/RISK_MATRIX       │
  └───────────────────┬─────────────────────────┘
                      │ WS "done" 事件
                      ▼
  ┌─────────────────────────────────────────────┐
  │      POST /api/vision/sessions               │
  │  儲存 VisionSession 到 SQLite:               │
  │  • mode, equipment_id                        │
  │  • vlm_prompt, vlm_result                    │
  │  • risk_level, vhs_score, five_s_score       │
  │  • detections (JSON array)                   │
  │  • pose_keypoints (JSON)                     │
  │  • track_history (JSON)                      │
  │  • person_count, vehicle_count, hazard_count │
  │  • duration_ms, thumbnail (base64)           │
  └─────────────────────────────────────────────┘
```

### MQTT 感應器資料流

```
工廠設備感應器 (溫度/震動/壓力/轉速)
        │ MQTT Publish
        ▼
  Eclipse Mosquitto (Port 1883)
        │ aiomqtt Subscribe
        ▼
  mqtt_listener() background task
        │ 解析 JSON payload
        ▼
  SQLite: MqttSensorReading
        │
        ├─▶ 警報閾值檢查 → EquipmentAlert
        └─▶ VHS 分數更新 → VhsReading
```

---

## YOLO 模型介紹

### YOLO26n — 物件偵測模型

| 屬性 | 值 |
|-----|-----|
| 模型名稱 | YOLO26n (Ultralytics YOLO v26 Nano) |
| 輸入格式 | `[1, 3, 640, 640]` — CHW float32 正規化 |
| 輸出格式 | `[1, 300, 6]` — E2E One-to-One Head (內建 NMS) |
| 輸出維度 | `[x1, y1, x2, y2, confidence, class_id]` |
| 類別數量 | 80 (COCO) |
| 模型大小 | ~9.4 MB ONNX |
| 推論後端 | onnxruntime-web 1.17.3 WASM |
| 執行環境 | 瀏覽器端 (macOS / iOS Safari) |

**E2E One-to-One Head 技術說明：**

傳統 YOLO (v8/v11) 輸出 `[1, 84, 8400]`，需要手動執行 NMS (Non-Maximum Suppression)。
YOLO26n 採用 **One-to-One Head** 架構，模型內部已完成最佳匹配，直接輸出最多 300 個最終偵測結果，無需後處理 NMS。

```typescript
// 後處理：只需過濾 confidence，不需 NMS
for (let i = 0; i < 300; i++) {
  const base = i * 6;
  const conf = data[base + 4];
  if (conf <= 0) continue;  // E2E: 未使用的 slot confidence = 0
  const classId = Math.round(data[base + 5]);
  // xyxy pixel → 正規化 0~1
  const x1 = Math.max(0, data[base + 0]) / 640;
  const y1 = Math.max(0, data[base + 1]) / 640;
  const x2 = Math.min(1, data[base + 2] / 640);
  const y2 = Math.min(1, data[base + 3] / 640);
}
```

**製造業危險物品優先排序：**

平台針對工廠場景，對 COCO 類別進行危險度分級，推論後依優先級排序：

```
CRITICAL (0.25)：剪刀、刀具、斧頭
HIGH    (0.30)：人員、機車、汽車、卡車、公車
MEDIUM  (0.35)：消防栓、停車計時器、紅綠燈
LOW     (0.40)：其他類別
```

### YOLO26n-Pose — 人員姿態估計模型

| 屬性 | 值 |
|-----|-----|
| 模型名稱 | YOLO26n-Pose (Ultralytics YOLO v26 Nano Pose) |
| 輸入格式 | `[1, 3, 640, 640]` — CHW float32 正規化 |
| 輸出格式 | `[1, 300, 57]` — E2E with 17 COCO Keypoints |
| 輸出維度 | `[x1, y1, x2, y2, conf, cls_id, kp0x, kp0y, kp0v, ... × 17]` |
| 關鍵點格式 | `[kpx_pixel, kpy_pixel, visibility]` × 17 |
| 模型大小 | ~12 MB ONNX |

**COCO 17 關鍵點定義：**

```
0=nose          1=left_eye      2=right_eye
3=left_ear      4=right_ear
5=left_shoulder  6=right_shoulder
7=left_elbow     8=right_elbow
9=left_wrist    10=right_wrist
11=left_hip     12=right_hip
13=left_knee    14=right_knee
15=left_ankle   16=right_ankle
```

**PPE 安全合規輔助：**
- 安全帽偵測：nose/eye/ear 關鍵點上方區域
- 反光衣：shoulder keypoints 間色彩分析（結合 VLM）
- 危險姿態：關鍵點角度計算（跌倒/蹲伏偵測）

### SORT 多目標追蹤器

基於 **IoU Greedy Matching** 的輕量追蹤演算法（參考 Bewley et al., 2016）：

```
每幀流程：
  1. 所有現有 Track age++
  2. 按信心度降序排列新偵測
  3. 計算偵測 × Track 的 IoU 矩陣
     - 同類別 IoU 正常計算
     - 跨類別 IoU × 0.5（降低跨類誤配）
  4. 貪婪匹配：IoU > 0.25 → 更新 Track
  5. 未匹配偵測 → 新建 Track（分配唯一 trackId）
  6. age > maxAge(5) → 移除 Track
```

---

## AI 模型介紹

### VLM — 視覺語言模型

| 屬性 | 值 |
|-----|-----|
| 模型 | gemma4:e4b (Google Gemma 4 4B 量化版) |
| 量化 | Q4_K_M (4-bit Mixed Precision) |
| Context | 128K tokens |
| 推論速度 | 30–50 tok/s (M4 Max / Jetson AGX Orin) |
| 推論後端 | llama.cpp (HTTP Server Mode) |
| 通訊協定 | WebSocket 串流輸出 |
| 輸入能力 | 圖像 + 文字（多模態） |

**四大模式 Expert-level VLM Prompt 設計：**

每個模式的 Prompt 採用角色定義 + 結構化輸出格式，確保 VLM 產生可解析的結構化響應：

```
[設備巡檢] 角色：工廠設備安全工程師
  → DETECT: 設備清單
  → ENV: 環境狀況
  → VHS: 設備健康分數 [0-100]
  → 5S: 整理/整頓/清掃/清潔/素養 各項分數
  → RISK_MATRIX: 風險等級 × 發生可能性

[人員辨識] 角色：工業安全稽核員
  → 姿態異常評估
  → PPE 合規率
  → 危險行為偵測

[事件偵測] 角色：保全監控分析師
  → 入侵事件
  → 軌跡異常
  → 即時警報等級

[物品辨識] 角色：倉儲品質管制工程師
  → 物料清點
  → 違規物品
  → 5S 符合度
```

### RAG 知識庫系統

| 組件 | 技術 | 說明 |
|-----|------|------|
| 向量資料庫 | ChromaDB (本地) | 持久化儲存，支援語意相似度搜尋 |
| 嵌入模型 | nomic-embed-text | 高效文字嵌入，768 維向量 |
| 切分策略 | 遞迴字符切分 | chunk_size=500, overlap=50 |
| 支援格式 | PDF / TXT / MD / CSV | 自動解析與切分 |
| 問答模型 | gemma4:e4b | 結合檢索結果生成答案 |

---

## 快速開始

### 前置需求

- macOS (Apple Silicon M1/M2/M3/M4 推薦) 或 Jetson AGX Orin
- Docker Desktop 24+ / Docker Engine 24+
- 8GB+ RAM（模型推論建議 16GB+）
- llama.cpp server 運行中（含 gemma4:e4b 模型）

### 1. 複製專案

```bash
git clone https://github.com/guessleej/xCloudVLMui.git
cd xCloudVLMui
```

### 2. 環境設定

```bash
cp backend/.env.example backend/.env
# 編輯 backend/.env，設定必要參數：
# LLM_BASE_URL=http://host.docker.internal:8080
# SECRET_KEY=your-secret-key-here
# ALLOWED_ORIGINS=http://localhost:3110
```

### 3. 放入 YOLO 模型

```bash
# 將 ONNX 模型放入 frontend/public/models/
cp yolo26n.onnx       frontend/public/models/
cp yolo26n-pose.onnx  frontend/public/models/
```

### 4. 啟動服務

```bash
# macOS 本機開發
make dev-mac

# 或直接使用 Docker Compose
docker compose -f docker-compose.mac.yml up -d
```

### 5. 開啟應用

| 服務 | URL |
|-----|-----|
| 主介面 | http://localhost:3110 |
| API Docs | http://localhost:8201/docs |
| Prometheus Metrics | http://localhost:8201/metrics |

---

## CI/CD 流程

### 本機開發流程

```
修改程式碼
    │
    ▼
make lint          # ESLint + Ruff + mypy
    │
    ▼
make test          # pytest (backend) + jest (frontend)
    │
    ▼
docker compose build   # 建立映像
    │
    ▼
make dev-mac       # 本機驗證
```

### Docker 映像建置

#### Frontend Dockerfile（多階段建置）

```dockerfile
# Stage 1: 依賴安裝
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --production

# Stage 2: 建置
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# 複製 WASM 推論引擎
RUN cp -r node_modules/onnxruntime-web/dist/*.wasm public/ort/
RUN npm run build

# Stage 3: 執行
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/public ./public
EXPOSE 3000
CMD ["node", "server.js"]
```

#### Backend 服務

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### GitHub Actions 工作流程（建議設定）

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  backend-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: pip install -r backend/requirements.txt
      - run: cd backend && pytest tests/ -v

  frontend-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: cd frontend && npm ci
      - run: cd frontend && npm run build

  docker-build:
    needs: [backend-test, frontend-build]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker compose -f docker-compose.mac.yml build
```

### 版本發布流程

```
develop 分支（日常開發）
    │ PR 審核通過
    ▼
main 分支
    │ git tag v1.x.x
    ▼
GitHub Release
    │ Docker 映像打包
    ▼
離線部署包（AIR-030 / macOS）
    │ make package-offline
    ▼
Advantech AIR-030 / macOS 部署
```

---

## API 文件

啟動後訪問 http://localhost:8201/docs 查看完整 Swagger UI。

### 核心端點一覽

| 端點 | 方法 | 說明 |
|-----|------|------|
| `/api/auth/login` | POST | 使用者登入（取得 JWT） |
| `/api/vlm/stream` | WebSocket | VLM 推論串流 |
| `/api/vision/sessions` | POST | 儲存視覺分析 Session |
| `/api/vision/sessions` | GET | 查詢 Session 歷史 |
| `/api/vision/stats` | GET | 統計摘要 |
| `/api/equipment` | GET/POST | 設備管理 CRUD |
| `/api/vhs/readings` | GET | VHS 評分歷史 |
| `/api/alerts` | GET/POST/DELETE | 警報管理 |
| `/api/mqtt/devices` | GET | MQTT 設備清單 |
| `/api/knowledge/documents` | POST | 上傳知識庫文件 |
| `/api/chat` | POST | RAG 知識庫問答 |
| `/api/health` | GET | 服務健康狀態 |

---

## 專案結構

```
xCloudVLMui/
├── backend/                    # FastAPI 後端
│   ├── main.py                 # 應用入口 + 路由掛載
│   ├── config.py               # 環境設定（pydantic-settings）
│   ├── database.py             # SQLAlchemy async engine
│   ├── models/
│   │   ├── db_models.py        # ORM 資料表定義
│   │   └── schemas.py          # Pydantic 請求/響應模型
│   ├── routers/
│   │   ├── auth.py             # JWT 認證
│   │   ├── vlm.py              # VLM WebSocket 推論
│   │   ├── vision.py           # 視覺 Session CRUD
│   │   ├── equipment.py        # 設備管理
│   │   ├── vhs.py              # VHS 評分
│   │   ├── alerts.py           # 警報管理
│   │   ├── mqtt.py             # MQTT 設備資料
│   │   ├── knowledge.py        # 知識庫管理
│   │   ├── chat.py             # RAG 對話
│   │   └── settings.py         # 系統設定
│   └── services/
│       ├── mqtt_service.py     # MQTT 監聽背景任務
│       ├── rag_service.py      # ChromaDB RAG
│       └── report_service.py   # 報告生成
│
├── frontend/                   # Next.js 14 前端
│   ├── app/
│   │   ├── main/vlm/           # 視覺巡檢指揮台
│   │   ├── main/dashboard/     # 設備健康儀表板
│   │   ├── main/settings/      # 系統設定
│   │   └── main/reports/       # 分析報告
│   ├── components/
│   │   └── vlm/
│   │       └── camera-stream.tsx  # 相機串流 + YOLO + VLM
│   ├── hooks/
│   │   ├── useYolo.ts          # YOLO26n 物件偵測
│   │   └── useYoloPose.ts      # YOLO26n-Pose 姿態估計
│   ├── lib/
│   │   └── yoloTracker.ts      # SORT 多目標追蹤器
│   └── public/
│       ├── models/             # ONNX 模型（yolo26n + pose）
│       └── ort/                # onnxruntime-web WASM 檔案
│
├── nginx/                      # Nginx 反向代理設定
├── mosquitto/                  # MQTT Broker 設定
├── models/                     # LLM 模型存放（.gguf）
├── docker-compose.mac.yml      # macOS 開發環境
├── docker-compose.yml          # 正式部署
├── Makefile                    # 常用指令集
└── docs/                       # 詳細技術文件
```

---

## 版本歷史

| 版本 | 日期 | 主要更新 |
|-----|------|---------|
| v1.1.0 | 2026-04 | 多模態 YOLO26n E2E + SORT 追蹤 + Vision Session DB + Expert VLM Prompts |
| v1.0.0 | 2025-12 | 初始發布：VLM 推論 + MQTT + RAG + 設備健康管理 |

---

<div align="center">

**云碩科技 xCloudinfo Corp.Limited**

專為邊緣 AI 設計 · 本地優先 · 資料不上雲

</div>
