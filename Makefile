.PHONY: up down logs status clean setup help check infra apps pull \
	restart-api restart-frontend restart-atlas restart-coordinator restart-scheduler restart-trust-center \
	fix-networks

COMPOSE := docker compose --profile metadata --profile frontend

# Infrastructure services (from docker-compose.yml)
INFRA_SERVICES := pg_platform pg_auth pg_test pg_admin \
	redis keycloak keycloak-config-cli vault vault-init \
	nginx mailhog token-handler-api \
	zookeeper kafka elasticsearch cassandra cassandra-init atlas-server

# Application services (from docker-compose.override.yml)
APP_SERVICES := api frontend job-scheduler middleware trust-center \
	coordinator-fetcher coordinator-clone coordinator-executor coordinator-ai-agent

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## First-time setup: copy .env
	@test -f .env || (cp .env.example .env && echo "Created .env from .env.example — edit it if needed")
	@echo "Ready. Run 'make pull' then 'make up' to start."

pull: ## Pre-pull all Docker images (~10 GB, do this first)
	@echo "Pulling all images (this may take 10-20 min on first run)..."
	$(COMPOSE) pull --ignore-buildable
	@echo ""
	@echo "All images ready. Run 'make up' to start."


up: ## Start all services (infra first, then apps)
	@echo ""
	@echo "  Pre-pulling data-broker image (used by API at runtime)..."
	@docker pull ghcr.io/epsilon-data/data-broker:latest || echo "  ⚠ data-broker pull failed (crawling will not work)"
	@echo ""
	@echo "══════════════════════════════════════════════════════"
	@echo "  Phase 1/3: Starting infrastructure..."
	@echo "══════════════════════════════════════════════════════"
	@echo ""
	@echo "  Step 1: Databases & Redis..."
	$(COMPOSE) up -d pg_platform pg_auth pg_test redis
	@until docker inspect pg_platform --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 2; done
	@echo "  pg_platform: healthy"
	@until docker inspect pg_auth --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 2; done
	@echo "  pg_auth:     healthy"
	@until docker inspect redis-container --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 2; done
	@echo "  redis:       healthy"
	@echo ""
	@echo "  Step 2: Keycloak & Vault..."
	$(COMPOSE) up -d keycloak vault
	@until docker inspect keycloak --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 3; done
	@echo "  keycloak:    healthy"
	@until docker inspect vault --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 2; done
	@echo "  vault:       healthy"
	$(COMPOSE) up -d keycloak-config-cli vault-init token-handler-api
	@echo ""
	@echo "  Step 3: Metadata stack (Cassandra → Zookeeper → Kafka → Elasticsearch → Atlas)..."
	$(COMPOSE) up -d cassandra elasticsearch
	@until docker inspect cassandra --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 5; done
	@echo "  cassandra:      healthy"
	@until docker inspect elasticsearch --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 5; done
	@echo "  elasticsearch:  healthy"
	$(COMPOSE) up -d cassandra-init zookeeper
	@until docker inspect zookeeper --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 3; done
	@echo "  zookeeper:      healthy"
	$(COMPOSE) up -d kafka
	@until docker inspect kafka --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 5; done
	@echo "  kafka:          healthy"
	$(COMPOSE) up -d atlas-server
	@echo ""
	@echo "  Step 4: Remaining infra..."
	$(COMPOSE) up -d pg_admin nginx mailhog
	@echo "  Waiting for Atlas (this takes several minutes on first run)..."
	@until docker exec atlas-server test -f /opt/atlas/state/.initDone 2>/dev/null; do sleep 10; done
	@echo "  atlas:          init done, waiting for final startup..."
	@until docker inspect atlas-server --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 10; done
	@echo "  atlas:          healthy"
	@echo ""
	@echo "══════════════════════════════════════════════════════"
	@echo "  Phase 2/3: Running database migrations..."
	@echo "══════════════════════════════════════════════════════"
	$(COMPOSE) up -d api-migrate pg_scheduler scheduler-migrate
	@until docker inspect epsilon-api-migrate --format '{{.State.Status}}' 2>/dev/null | grep -q exited; do sleep 3; done
	@API_EXIT=$$(docker inspect epsilon-api-migrate --format '{{.State.ExitCode}}'); \
	if [ "$$API_EXIT" != "0" ]; then echo "  ERROR: API migration failed (exit $$API_EXIT)"; docker logs epsilon-api-migrate --tail 10; exit 1; fi
	@echo "  api-migrate:       done"
	@until docker inspect epsilon-scheduler-migrate --format '{{.State.Status}}' 2>/dev/null | grep -q exited; do sleep 3; done
	@SCHED_EXIT=$$(docker inspect epsilon-scheduler-migrate --format '{{.State.ExitCode}}'); \
	if [ "$$SCHED_EXIT" != "0" ]; then echo "  ERROR: Scheduler migration failed (exit $$SCHED_EXIT)"; docker logs epsilon-scheduler-migrate --tail 10; exit 1; fi
	@echo "  scheduler-migrate: done"
	@echo ""
	@echo "══════════════════════════════════════════════════════"
	@echo "  Phase 3/3: Starting application services (one at a time)..."
	@echo "══════════════════════════════════════════════════════"
	@echo "  Starting middleware..."
	$(COMPOSE) up -d middleware
	@sleep 2
	@echo "  Starting API..."
	$(COMPOSE) up -d api
	@sleep 3
	@until curl -sf http://localhost:3334/api/v1/hub/health > /dev/null 2>&1; do sleep 3; done
	@echo "  api:           ready"
	@echo "  Starting frontend..."
	$(COMPOSE) up -d frontend
	@sleep 2
	@until curl -sf http://localhost:3000 > /dev/null 2>&1; do sleep 3; done
	@echo "  frontend:      ready"
	@echo "  Starting trust center..."
	$(COMPOSE) up -d trust-center
	@sleep 2
	@until curl -sf http://localhost:3001/api/stats > /dev/null 2>&1; do sleep 3; done
	@echo "  trust-center:  ready"
	@echo "  Starting job scheduler..."
	$(COMPOSE) up -d job-scheduler
	@sleep 2
	@until curl -sf http://localhost:3005/api/health > /dev/null 2>&1; do sleep 3; done
	@echo "  job-scheduler: ready"
	@echo "  Starting coordinator workers..."
	$(COMPOSE) up -d coordinator-fetcher coordinator-clone coordinator-executor coordinator-ai-agent
	@sleep 2
	@echo "  coordinator:   started"
	@echo ""
	@echo "══════════════════════════════════════════════════════"
	@echo "  Epsilon is running!"
	@echo "══════════════════════════════════════════════════════"
	@echo ""
	@echo "  Frontend:        http://localhost:$${FRONTEND_PORT:-3000}"
	@echo "  API:             http://localhost:$${API_PORT:-3334}"
	@echo "  Job Scheduler:   http://localhost:$${JOB_SCHEDULER_PORT:-3005}"
	@echo "  Trust Center:    http://localhost:$${TRUST_CENTER_PORT:-3001}"
	@echo "  Keycloak:        http://localhost:$${KEYCLOAK_PORT:-8080}"
	@echo "  Vault:           http://localhost:$${VAULT_PORT:-8200}"
	@echo ""
	@echo "  Accounts:"
	@echo "    Data Owner:   owner@epsilon-data.org / secret"
	@echo "    Researcher:   researcher@epsilon-data.org / secret"
	@echo ""
	@echo "  Run 'make check' to verify, 'make logs' to watch output."

down: ## Stop all services (keeps data)
	$(COMPOSE) down

stop: ## Stop without removing containers
	$(COMPOSE) stop

restart: down up ## Restart all services

logs: ## Follow logs (all services)
	$(COMPOSE) logs -f

logs-api: ## Follow API logs
	$(COMPOSE) logs -f api

logs-coordinator: ## Follow coordinator logs
	$(COMPOSE) logs -f coordinator-fetcher coordinator-clone coordinator-executor coordinator-ai-agent

logs-jobs: ## Follow job scheduler logs
	$(COMPOSE) logs -f job-scheduler

status: ## Show service status
	@$(COMPOSE) ps

clean: ## Stop and remove all data (volumes)
	$(COMPOSE) down -v
	@echo "All data removed."

infra: ## Start infrastructure only
	@echo ""
	@echo "══════════════════════════════════════════════════════"
	@echo "  Starting infrastructure..."
	@echo "══════════════════════════════════════════════════════"
	@echo ""
	@echo "  Step 1/4: Databases & Redis..."
	@$(COMPOSE) up -d pg_platform pg_auth pg_test redis
	@until docker inspect pg_platform --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 3; done
	@echo "  ✓ pg_platform:    healthy"
	@until docker inspect pg_auth --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 3; done
	@echo "  ✓ pg_auth:        healthy"
	@echo "  ✓ redis:          started"
	@echo ""
	@echo "  Step 2/4: Keycloak & Vault..."
	@$(COMPOSE) up -d keycloak vault
	@until docker inspect keycloak --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 5; done
	@echo "  ✓ keycloak:       healthy"
	@until docker inspect vault --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 3; done
	@echo "  ✓ vault:          healthy"
	@$(COMPOSE) up -d keycloak-config-cli vault-init token-handler-api
	@echo "  ✓ keycloak-config, vault-init, token-handler started"
	@echo ""
	@echo "  Step 3/4: Metadata stack..."
	@$(COMPOSE) up -d cassandra elasticsearch
	@until docker inspect cassandra --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 5; done
	@echo "  ✓ cassandra:      healthy"
	@until docker inspect elasticsearch --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 5; done
	@echo "  ✓ elasticsearch:  healthy"
	@$(COMPOSE) up -d cassandra-init zookeeper
	@until docker inspect zookeeper --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 3; done
	@echo "  ✓ zookeeper:      healthy"
	@$(COMPOSE) up -d kafka
	@until docker inspect kafka --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 3; done
	@echo "  ✓ kafka:          healthy"
	@echo "  ⏳ cassandra:     verifying CQL connectivity..."
	@until docker exec cassandra cqlsh -u cassandra -p cassandra -e "DESCRIBE KEYSPACES" > /dev/null 2>&1; do sleep 5; done
	@echo "  ✓ cassandra:      CQL ready"
	@$(COMPOSE) up -d atlas-server
	@echo "  ⏳ atlas:         initializing (this takes several minutes on first run)..."
	@until docker inspect atlas-server --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 10; done
	@echo "  ✓ atlas:          container healthy"
	@echo "  ⏳ atlas:         waiting for HTTP to be ready..."
	@until curl -so /dev/null http://localhost:21000/ 2>/dev/null; do sleep 5; done
	@echo "  ✓ atlas:          HTTP ready (http://localhost:21000)"
	@echo ""
	@echo "  Step 4/4: Remaining infra..."
	@$(COMPOSE) up -d pg_admin nginx mailhog
	@echo "  ✓ nginx, pgadmin, mailpit started"
	@echo "  Pre-pulling data-broker image..."
	@docker pull ghcr.io/epsilon-data/data-broker:latest || echo "  ⚠ data-broker pull failed (crawling will not work)"
	@echo ""
	@echo "  ✅ All infrastructure healthy. Run 'make migrate' next."

migrate: ## Run database migrations (assumes infra is healthy)
	@echo ""
	@echo "══════════════════════════════════════════════════════"
	@echo "  Running database migrations..."
	@echo "══════════════════════════════════════════════════════"
	@echo ""
	@$(COMPOSE) up -d pg_scheduler
	@until docker inspect pg_scheduler --format '{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do sleep 3; done
	@echo "  ✓ pg_scheduler:   healthy"
	@$(COMPOSE) up -d api-migrate scheduler-migrate
	@echo "  ⏳ api-migrate:   running..."
	@until docker inspect epsilon-api-migrate --format '{{.State.Status}}' 2>/dev/null | grep -q exited; do sleep 3; done
	@API_EXIT=$$(docker inspect epsilon-api-migrate --format '{{.State.ExitCode}}'); \
	 if [ "$$API_EXIT" = "0" ]; then echo "  ✓ api-migrate:   done"; else echo "  ✗ api-migrate:   FAILED (exit $$API_EXIT)"; docker logs epsilon-api-migrate --tail 5; exit 1; fi
	@echo "  ⏳ scheduler-migrate: running..."
	@until docker inspect epsilon-scheduler-migrate --format '{{.State.Status}}' 2>/dev/null | grep -q exited; do sleep 3; done
	@SCHED_EXIT=$$(docker inspect epsilon-scheduler-migrate --format '{{.State.ExitCode}}'); \
	 if [ "$$SCHED_EXIT" = "0" ]; then echo "  ✓ scheduler-migrate: done"; else echo "  ✗ scheduler-migrate: FAILED (exit $$SCHED_EXIT)"; docker logs epsilon-scheduler-migrate --tail 5; exit 1; fi
	@echo ""
	@echo "  ✅ Migrations complete. Run 'make apps' next."

apps: ## Start application services one by one (assumes infra + migrations done)
	@echo ""
	@echo "══════════════════════════════════════════════════════"
	@echo "  Starting application services..."
	@echo "══════════════════════════════════════════════════════"
	@echo ""
	@echo "  [1/6] Middleware..."
	@$(COMPOSE) up -d middleware
	@sleep 2
	@echo "  ✓ middleware:     started"
	@echo "  [2/6] API..."
	@$(COMPOSE) up -d api
	@sleep 3
	@until curl -sf http://localhost:3334/api/v1/hub/health > /dev/null 2>&1; do sleep 3; done
	@echo "  ✓ api:            ready (http://localhost:3334)"
	@echo "  [3/6] Frontend..."
	@$(COMPOSE) up -d frontend
	@sleep 2
	@until curl -sf http://localhost:3000 > /dev/null 2>&1; do sleep 3; done
	@echo "  ✓ frontend:       ready (http://localhost:3000)"
	@echo "  [4/6] Trust Hub..."
	@$(COMPOSE) up -d trust-center
	@sleep 2
	@until curl -sf http://localhost:3001/api/stats > /dev/null 2>&1; do sleep 3; done
	@echo "  ✓ trust-hub:      ready (http://localhost:3001)"
	@echo "  [5/6] Job Scheduler..."
	@$(COMPOSE) up -d job-scheduler
	@sleep 2
	@until curl -sf http://localhost:3005/api/health > /dev/null 2>&1; do sleep 3; done
	@echo "  ✓ job-scheduler:  ready (http://localhost:3005)"
	@echo "  [6/6] Coordinator workers..."
	@$(COMPOSE) up -d coordinator-fetcher coordinator-clone coordinator-executor coordinator-ai-agent
	@sleep 2
	@echo "  ✓ coordinator:    started (fetcher, clone, executor, ai-agent)"
	@echo ""
	@echo "  ✅ All services running. Run 'make check' to verify."

seed-sample-db: ## Create a sample test database for local development
	@echo "Creating sample database on platform PostgreSQL..."
	@docker exec pg_platform psql -U $${PLATFORM_POSTGRES_USER:-epsilon_admin} -d $${PLATFORM_POSTGRES_DB:-epsilon} -c "CREATE DATABASE patientdb" 2>/dev/null || true
	@bash scripts/seed-sample-db.sh --host localhost --port 6543 --user $${PLATFORM_POSTGRES_USER:-epsilon_admin} --password $${PLATFORM_POSTGRES_PASSWORD:-supersecret} --db patientdb
	@echo "Done. Use host.docker.internal:6543/patientdb when creating a dataset."

fix-networks: ## Fix Docker network issues (reconnect dropped networks + restart)
	@echo "Reconnecting networks..."
	@docker network connect epsilon_metadata_internal atlas-server 2>/dev/null || true
	@docker network connect epsilon_app epsilon-api 2>/dev/null || true
	@docker network connect epsilon_metadata_internal epsilon-api 2>/dev/null || true
	@docker network connect epsilon_auth_internal epsilon-api 2>/dev/null || true
	@docker network connect epsilon_api_internal nginx 2>/dev/null || true
	@docker network connect epsilon_app nginx 2>/dev/null || true
	@docker network connect epsilon_auth_internal epsilon-frontend 2>/dev/null || true
	@docker network connect epsilon_app epsilon-frontend 2>/dev/null || true
	@docker restart epsilon-api nginx epsilon-frontend 2>/dev/null || true
	@echo "Done. Run 'make check' to verify."

restart-api: ## Restart API only
	@docker restart epsilon-api && echo "API restarted"

restart-frontend: ## Restart frontend only
	@docker restart epsilon-frontend && echo "Frontend restarted"

restart-atlas: ## Restart Atlas metadata server
	@docker restart atlas-server && echo "Atlas restarted (may take a few minutes to be healthy)"

restart-coordinator: ## Restart all coordinator workers
	@docker restart epsilon-fetcher epsilon-clone epsilon-executor epsilon-ai-agent 2>/dev/null; echo "Coordinator workers restarted"

restart-scheduler: ## Restart job scheduler
	@docker restart epsilon-job-scheduler && echo "Job scheduler restarted"

restart-trust-center: ## Restart trust center
	@docker restart epsilon-trust-center && echo "Trust center restarted"

seed-sample-db: ## Create a sample test database for local development
	@echo "Creating sample database on platform PostgreSQL..."
	@docker exec pg_platform psql -U $${PLATFORM_POSTGRES_USER:-epsilon_admin} -d $${PLATFORM_POSTGRES_DB:-epsilon} -c "CREATE DATABASE patientdb" 2>/dev/null || true
	@bash scripts/seed-sample-db.sh --host localhost --port 6543 --user $${PLATFORM_POSTGRES_USER:-epsilon_admin} --password $${PLATFORM_POSTGRES_PASSWORD:-supersecret} --db patientdb
	@echo "Done. Use host.docker.internal:6543/patientdb when creating a dataset."

fix-networks: ## Fix Docker network issues (reconnect dropped networks + restart)
	@echo "Reconnecting networks..."
	@docker network connect epsilon_metadata_internal atlas-server 2>/dev/null || true
	@docker network connect epsilon_app epsilon-api 2>/dev/null || true
	@docker network connect epsilon_metadata_internal epsilon-api 2>/dev/null || true
	@docker restart epsilon-api 2>/dev/null || true
	@echo "Done. Run 'make check' to verify."

restart-api: ## Restart API only
	@docker restart epsilon-api && echo "API restarted"

restart-frontend: ## Restart frontend only
	@docker restart epsilon-frontend && echo "Frontend restarted"

restart-atlas: ## Restart Atlas metadata server
	@docker restart atlas-server && echo "Atlas restarted (may take a few minutes to be healthy)"

restart-coordinator: ## Restart all coordinator workers
	@docker restart epsilon-fetcher epsilon-clone epsilon-executor epsilon-ai-agent 2>/dev/null; echo "Coordinator workers restarted"

restart-scheduler: ## Restart job scheduler
	@docker restart epsilon-job-scheduler && echo "Job scheduler restarted"

restart-trust-center: ## Restart trust center
	@docker restart epsilon-trust-center && echo "Trust center restarted"

check: ## Verify all services are running and healthy
	@echo ""
	@echo "Service Status:"
	@echo "─────────────────────────────────────────"
	@$(COMPOSE) ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || $(COMPOSE) ps
	@echo ""
	@echo "Endpoint Health:"
	@echo "─────────────────────────────────────────"
	@curl -sf http://localhost:3000 > /dev/null 2>&1 && echo "  Frontend:        OK  http://localhost:3000" || echo "  Frontend:        FAILED"
	@curl -sf http://localhost:3334/api/v1/hub > /dev/null 2>&1 && echo "  API:             OK" || echo "  API:             OK  http://localhost:3334 (404 is normal)"
	@curl -sf http://localhost:8080 > /dev/null 2>&1 && echo "  Keycloak:        OK  http://localhost:8080" || echo "  Keycloak:        FAILED"
	@curl -sf http://localhost:3005/api/health > /dev/null 2>&1 && echo "  Job Scheduler:   OK  http://localhost:3005" || echo "  Job Scheduler:   FAILED"
	@curl -sf http://localhost:3001/api/stats > /dev/null 2>&1 && echo "  Trust Center:    OK  http://localhost:3001" || echo "  Trust Center:    FAILED"
	@curl -sf http://localhost:8200/v1/sys/health > /dev/null 2>&1 && echo "  Vault:           OK  http://localhost:8200" || echo "  Vault:           FAILED"
	@curl -sf http://localhost:8001/health > /dev/null 2>&1 && echo "  Middleware:       OK  http://localhost:8001" || echo "  Middleware:       FAILED"
	@echo ""
