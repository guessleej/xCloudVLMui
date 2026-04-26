<!-- xCloudVLMui — Multi-Platform README -->
<div align="center">

# xCloudVLMui Platform

**工廠設備健康管理平台 · 工廠視覺 AI 指揮台**

[![Python](https://img.shields.io/badge/Python-3.11-3776ab?logo=python&logoColor=white)]()
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110-009688?logo=fastapi&logoColor=white)]()
[![Next.js](https://img.shields.io/badge/Next.js-14-000000?logo=nextdotjs&logoColor=white)]()
[![Docker](https://img.shields.io/badge/Docker-Compose%20v2-2496ED?logo=docker&logoColor=white)]()
[![License](https://img.shields.io/badge/License-Proprietary-red)]()

> 由 **云碩科技 xCloudinfo Corp.Limited** 開發  
> 支援多硬體平台的邊緣 AI 部署框架 — RAG · VLM · MQTT · YOLO

</div>

---

## 支援硬體平台

**每種設備硬體核心不同，各自維護獨立 repo**，確保套件安裝、驅動相依與 Docker 設定完全隔離，互不干涉。

> ⚠️ 部署前請確認設備型號，clone **對應設備的專屬 repo**，勿混用。

| 設備 Repo | 硬體 | Project Name | 前綴 | 架構 | Port 入口 |
|-----------|------|-------------|------|------|-----------|
| [`xCloudVLMui`](https://github.com/guessleej/xCloudVLMui) | 通用基底（本 repo） | `xcloudvlmui-platform` | 無 | 共用 | — |
| [`xCloudVLMui-dgx-spark`](https://github.com/guessleej/xCloudVLMui-dgx-spark) | NVIDIA DGX Spark | `xcloudvlmui-dgx-spark` | `dgx-spark-` | ARM64 | `:8780` |
| [`xCloudVLMui-mic743`](https://github.com/guessleej/xCloudVLMui-mic743) | Advantech MIC-743 | `xcloudvlmui-mic743` | `mic743-` | ARM64 | `:8780` |
| [`xCloudVLMui-air030`](https://github.com/guessleej/xCloudVLMui-air030) | Advantech AIR-030 | `xcloudvlmui-air030` | `air030-` | ARM64 | `:8780` |
| [`xCloudVLMui-x86`](https://github.com/guessleej/xCloudVLMui-x86) | x86-64 Linux | `xcloudvlmui-x86` | `x86-` | AMD64 | `:8680` |
| [`xCloudVLMui-macOS`](https://github.com/guessleej/xCloudVLMui-macOS) | Apple Silicon Mac | `xcloudvlmui-mac` | `mac-` | ARM64 | `:8880` |

---

## 系統功能

```
┌──────────────────────────────────────────────────────┐
│                  xCloudVLMui Platform                 │
│                                                      │
│  ┌─ nginx ──────────────────────────────────────┐   │
│  │  ┌─ frontend (Next.js 14) ─────────────────┐ │   │
│  │  │  視覺巡檢 · MQTT · RAG · 模型管理         │ │   │
│  │  │  事件中心 · 知識庫 · 系統設定             │ │   │
│  │  └──────────────────────────────────────────┘ │   │
│  │  ┌─ backend (FastAPI) ─────────────────────┐  │   │
│  │  │  SQLite · ChromaDB · RAG pipeline       │  │   │
│  │  │  MQTT broker · YOLO inference           │  │   │
│  │  └──────────────────────────────────────────┘ │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌─ LLM (llama.cpp / Ollama) ───────────────────┐   │
│  │  Gemma 4 E4B · bge-m3 embedding              │   │
│  │  qwen3-vl VLM 視覺推論                        │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌─ vlm-webui ──┐  ┌─ mosquitto ──┐  ┌─ cadvisor ─┐ │
│  │  視覺串流    │  │  MQTT Broker │  │  容器監控  │ │
│  └─────────────┘  └──────────────┘  └────────────┘ │
└──────────────────────────────────────────────────────┘
```

### 核心模組

| 模組 | 說明 |
|------|------|
| **RAG 知識問答** | ChromaDB 向量索引 + bge-m3 嵌入 + LLM 生成，支援 PDF/TXT/MD/圖片 OCR |
| **VLM 視覺推論** | WebRTC 相機串流 + qwen3-vl 即時分析，支援多種 YOLO 模型 |
| **設備健康管理** | VHS 趨勢分析、警報系統、維修報告自動生成 |
| **MQTT IoT** | 感測器資料收集、閾值警報、即時儀表板 |
| **事件中心** | 工廠事件記錄、批次管理、MD 匯出 |
| **模型管理** | YOLO detect/pose/segment/classify 多模型熱切換 |

---

## 快速啟動

> ⚠️ 請 clone **對應你設備型號的 repo**，不同硬體的套件與驅動設定不可混用。

```bash
# ── 依設備型號選擇對應 repo ──────────────────────────────────────

# NVIDIA DGX Spark
git clone https://github.com/guessleej/xCloudVLMui-dgx-spark.git

# Advantech MIC-743
git clone https://github.com/guessleej/xCloudVLMui-mic743.git

# Advantech AIR-030
git clone https://github.com/guessleej/xCloudVLMui-air030.git

# x86-64 Linux
git clone https://github.com/guessleej/xCloudVLMui-x86.git

# Apple Silicon Mac
git clone https://github.com/guessleej/xCloudVLMui-macOS.git

# ── 啟動流程（各 repo 相同）──────────────────────────────────────
cd xCloudVLMui-<設備名稱>

# 1. 設定環境變數
make setup

# 2. 啟動服務
make up

# 3. 驗證
make test
```

---

## 技術架構

| 層級 | 技術 |
|------|------|
| **前端** | Next.js 14 · TypeScript · Tailwind CSS · React |
| **後端** | FastAPI · SQLAlchemy · aiosqlite · Pydantic v2 |
| **向量資料庫** | ChromaDB (persistent) |
| **LLM/Embedding** | Ollama / llama.cpp — Gemma 4 E4B · bge-m3 |
| **VLM** | qwen3-vl:30b 視覺推論 |
| **物件偵測** | YOLO11 / YOLO World (ONNX) |
| **訊息佇列** | Eclipse Mosquitto MQTT 2.0 |
| **容器化** | Docker Compose v2 · 多平台 ARM64/AMD64 |

---

<div align="center">

**云碩科技 xCloudinfo Corp.Limited**  
Edge AI · Industrial Vision · Smart Factory

</div>
