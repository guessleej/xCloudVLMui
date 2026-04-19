###############################################################################
# Makefile — xCloudVLMui Platform [bot-mac 獨立實例]
#
# ┌─ 首次部署 ──────────────────────────────────────────────────────────┐
# │  make setup        # 複製 .env                                      │
# │  make up           # 啟動所有 Docker 服務                           │
# │  make test         # 驗證所有服務健康狀態                           │
# └────────────────────────────────────────────────────────────────────┘
#
# Port 配置（獨立，不與 bot-air030 衝突）：
#   nginx    → http://localhost:8980
#   backend  → http://localhost:8201/api/health
#   frontend → http://localhost:3200
#   cadvisor → http://localhost:8291
###############################################################################

.PHONY: all setup env-copy build up down restart \
        logs logs-llm logs-backend logs-frontend logs-mqtt status test ps clean clean-all

COMPOSE      := docker compose
COMPOSE_FILE := -f docker-compose.mac.yml
SCRIPTS_DIR  := scripts

# ── 顏色 ─────────────────────────────────────────────────────────────
BLUE   := \033[0;34m
GREEN  := \033[0;32m
YELLOW := \033[1;33m
RED    := \033[0;31m
NC     := \033[0m

# ── 預設目標 ─────────────────────────────────────────────────────────
all: help

help:
	@echo ""
	@printf "$(BLUE)╔══════════════════════════════════════════════════════╗$(NC)\n"
	@printf "$(BLUE)║     xCloudVLMui Platform — bot-mac 獨立實例          ║$(NC)\n"
	@printf "$(BLUE)╠══════════════════════════════════════════════════════╣$(NC)\n"
	@printf "$(BLUE)║  Port: nginx:3110  backend:8201  frontend:3200       ║$(NC)\n"
	@printf "$(BLUE)╚══════════════════════════════════════════════════════╝$(NC)\n"
	@echo ""
	@printf "$(YELLOW)首次部署：$(NC)\n"
	@printf "  make setup          複製 .env 範本（填入設定後再 make up）\n"
	@printf "  make up             建置並啟動所有服務\n"
	@printf "  make test           驗證所有服務健康狀態\n"
	@echo ""
	@printf "$(YELLOW)日常操作：$(NC)\n"
	@printf "  make logs           查看所有服務 log\n"
	@printf "  make logs-backend   只看 backend log\n"
	@printf "  make logs-frontend  只看 frontend log\n"
	@printf "  make logs-mqtt      只看 mosquitto log\n"
	@printf "  make status         顯示容器狀態\n"
	@printf "  make ps             顯示容器列表\n"
	@printf "  make restart        重啟所有服務\n"
	@printf "  make down           停止容器\n"
	@printf "  make clean          停止並移除容器（保留資料）\n"
	@printf "  make clean-all      完全清除（含 Volume 資料庫）\n"
	@echo ""

# ─────────────────────────────────────────────────────────────────────
# 首次設定
# ─────────────────────────────────────────────────────────────────────

setup: env-copy
	@printf "$(GREEN)✓ setup 完成！執行 make up 啟動服務。$(NC)\n"

env-copy:
	@printf "$(BLUE)► 設定環境變數...$(NC)\n"
	@if [ ! -f backend/.env ]; then \
		cp backend/.env.example backend/.env ; \
		printf "$(YELLOW)  ⚠ 已複製 backend/.env，請填入正確設定值。$(NC)\n" ; \
	else \
		printf "$(GREEN)  ✓ backend/.env 已存在。$(NC)\n" ; \
	fi
	@if [ ! -f frontend/.env.local ]; then \
		cp frontend/.env.local.example frontend/.env.local ; \
		printf "$(YELLOW)  ⚠ 已複製 frontend/.env.local，請填入 OAuth Client ID/Secret。$(NC)\n" ; \
	else \
		printf "$(GREEN)  ✓ frontend/.env.local 已存在。$(NC)\n" ; \
	fi

# ─────────────────────────────────────────────────────────────────────
# Docker 操作
# ─────────────────────────────────────────────────────────────────────

build:
	@printf "$(BLUE)► 建置 Docker 映像（bot-mac）...$(NC)\n"
	$(COMPOSE) $(COMPOSE_FILE) build --parallel

up:
	@printf "$(BLUE)► 啟動 xCloudVLMui [bot-mac] 服務...$(NC)\n"
	$(COMPOSE) $(COMPOSE_FILE) up -d --build
	@echo ""
	@printf "$(GREEN)✓ 服務已啟動！$(NC)\n"
	@echo ""
	@printf "  Web UI   → $(BLUE)http://localhost:3110$(NC)\n"
	@printf "  API Docs → $(BLUE)http://localhost:3110/docs$(NC)\n"
	@printf "  Backend  → $(BLUE)http://localhost:8201/api/health$(NC)\n"
	@printf "  Frontend → $(BLUE)http://localhost:3200$(NC)\n"
	@printf "  cAdvisor → $(BLUE)http://localhost:8291$(NC)\n"

down:
	$(COMPOSE) $(COMPOSE_FILE) down

restart:
	$(COMPOSE) $(COMPOSE_FILE) restart

restart-backend:
	$(COMPOSE) $(COMPOSE_FILE) restart backend

restart-mqtt:
	$(COMPOSE) $(COMPOSE_FILE) restart mosquitto

# ─────────────────────────────────────────────────────────────────────
# 監控
# ─────────────────────────────────────────────────────────────────────

logs:
	$(COMPOSE) $(COMPOSE_FILE) logs -f --tail=100

logs-llm:
	$(COMPOSE) $(COMPOSE_FILE) logs -f --tail=100 llama-cpp

logs-backend:
	$(COMPOSE) $(COMPOSE_FILE) logs -f --tail=100 backend

logs-frontend:
	$(COMPOSE) $(COMPOSE_FILE) logs -f --tail=100 frontend

logs-mqtt:
	$(COMPOSE) $(COMPOSE_FILE) logs -f --tail=100 mosquitto

ps:
	$(COMPOSE) $(COMPOSE_FILE) ps

status:
	@printf "$(BLUE)── bot-mac 容器狀態 ───────────────────$(NC)\n"
	$(COMPOSE) $(COMPOSE_FILE) ps

# ─────────────────────────────────────────────────────────────────────
# 測試
# ─────────────────────────────────────────────────────────────────────

test:
	@printf "$(BLUE)► 驗證 bot-mac 服務健康狀態...$(NC)\n"
	@for url in \
		"http://localhost:8201/api/health" \
		"http://localhost:3200" \
		"http://localhost:3110/api/health" \
		"http://localhost:8291/healthz"; do \
		CODE=$$(curl -sk -o /dev/null -w "%{http_code}" --max-time 5 $$url 2>/dev/null || echo "ERR") ; \
		if [ "$$CODE" = "200" ]; then \
			printf "  $(GREEN)✓$(NC) %-45s → %s\n" "$$url" "$$CODE" ; \
		else \
			printf "  $(RED)✗$(NC) %-45s → %s\n" "$$url" "$$CODE" ; \
		fi ; \
	done

# ─────────────────────────────────────────────────────────────────────
# Shell 進入
# ─────────────────────────────────────────────────────────────────────

shell-backend:
	$(COMPOSE) $(COMPOSE_FILE) exec backend /bin/bash

shell-frontend:
	$(COMPOSE) $(COMPOSE_FILE) exec frontend /bin/sh

# ─────────────────────────────────────────────────────────────────────
# 清理
# ─────────────────────────────────────────────────────────────────────

clean:
	$(COMPOSE) $(COMPOSE_FILE) down --rmi local
	@printf "$(GREEN)✓ 容器已清除（資料 Volume 保留）。$(NC)\n"

clean-all:
	@printf "$(RED)⚠ 這將刪除 bot-mac 所有資料，包含資料庫與向量索引。$(NC)\n"
	@printf "$(YELLOW)確認？(y/N) $(NC)" ; read confirm ; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		$(COMPOSE) $(COMPOSE_FILE) down -v --rmi local ; \
		printf "$(GREEN)✓ 完全清除完成。$(NC)\n" ; \
	else \
		printf "已取消。\n" ; \
	fi
