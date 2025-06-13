NAME = inception
DOCKER_COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = .data

all: up

up:
	@echo "Starting $(NAME) containers..."
	@docker compose -f $(DOCKER_COMPOSE_FILE) up -d --build

down:
	@echo "Stopping $(NAME) containers..."
	@docker compose -f $(DOCKER_COMPOSE_FILE) down

stop:
	@echo "Stopping $(NAME) containers..."
	@docker compose -f $(DOCKER_COMPOSE_FILE) stop

start:
	@echo "Starting $(NAME) containers..."
	@docker compose -f $(DOCKER_COMPOSE_FILE) start

restart:
	@echo "Restarting $(NAME) containers..."
	@docker compose -f $(DOCKER_COMPOSE_FILE) restart

logs:
	@docker compose -f $(DOCKER_COMPOSE_FILE) logs

ps:
	@docker compose -f $(DOCKER_COMPOSE_FILE) ps

clean: down
	@echo "Removing project-specific containers, networks and images..."
	@docker container prune -f
	@docker network prune -f
	@echo "Removing project images..."
	@docker images | grep inception | awk '{print $$3}' | xargs -r docker image rm -f || true

fclean: clean
	@echo "Removing persistent volumes..."
	@rm -rf $(DATA_DIR)/mariadb/*
	@rm -rf $(DATA_DIR)/wordpress/*

re: fclean all

.PHONY: all up down stop start restart logs ps clean fclean re

# make Secrets
secrets:
	@echo "Creating secrets directory..."
	@mkdir -p secrets
	@echo "Creating database root password..."
	@test -f srcs/secrets/db_root_password.txt || echo "db_root_password" > srcs/secrets/db_root_password.txt
	@echo "Creating database user password..."
	@test -f srcs/secrets/db_password.txt || echo "db_password" > srcs/secrets/db_password.txt
	@echo "Creating WordPress admin password..."
	@test -f srcs/secrets/wp_admin_password.txt || echo "wp_admin_password" > srcs/secrets/wp_admin_password.txt
	@echo "Creating WordPress user password..."
	@test -f srcs/secrets/wp_user_password.txt || echo "wp_user_password" > srcs/secrets/wp_user_password.txt
	@echo "Secrets created successfully."

# Checking requirements
check: check-requirements check-containers check-services check-network check-volumes

check-requirements:
	@echo "🔍 Checking project requirements..."
	@echo "Checking directory structure..."
	@test -d srcs || (echo "❌ srcs directory missing" && exit 1)
	@test -f srcs/docker-compose.yml || (echo "❌ docker-compose.yml missing" && exit 1)
	@test -f srcs/.env || (echo "❌ .env file missing" && exit 1)
	@test -d srcs/requirements/nginx || (echo "❌ nginx directory missing" && exit 1)
	@test -d srcs/requirements/wordpress || (echo "❌ wordpress directory missing" && exit 1)
	@test -d srcs/requirements/mariadb || (echo "❌ mariadb directory missing" && exit 1)
	@echo "✅ Directory structure OK"

check-containers:
	@echo "🔍 Checking containers..."
	@docker compose -f $(DOCKER_COMPOSE_FILE) ps --format "table {{.State}}" | grep -q "running" || (echo "❌ Containers not running" && exit 1)
	@echo "✅ Containers are running"

check-services:
	@echo "🔍 Checking services..."
	@echo "- Checking NGINX (HTTPS only)..."
	@curl -k -s -o /dev/null -w "%{http_code}" https://localhost:443 | grep -q "200\|30[0-9]" || (echo "❌ NGINX HTTPS not working" && exit 1)
	@echo "- Checking HTTP redirect/block..."
	@! curl -s -o /dev/null http://localhost:80 2>/dev/null || (echo "❌ HTTP should not be accessible" && exit 1)
	@echo "- Checking WordPress..."
	@curl -k -s -L https://localhost:443 | grep -q "WordPress\|wp-" || (echo "❌ WordPress not detected" && exit 1)
	@echo "- Checking MariaDB connection..."
	@docker compose -f $(DOCKER_COMPOSE_FILE) exec mariadb mariadb-admin -u root -p$$(cat secrets/db_root_password.txt) ping || (echo "❌ MariaDB not responding" && exit 1)
	@echo "✅ All services working"

check-network:
	@echo "🔍 Checking docker network..."
	@docker network ls | grep -q inception_network || (echo "❌ Inception network missing" && exit 1)
	@echo "✅ Network configuration OK"

check-volumes:
	@echo "🔍 Checking volumes..."
	@docker volume ls | grep -q "mariadb\|wordpress" || (echo "❌ Required volumes missing" && exit 1)
	@echo "✅ Volumes configuration OK"

check-security:
	@echo "🔍 Security checks..."
	@echo "Checking TLS version..."
	@openssl s_client -connect localhost:443 -tls1_2 -quiet < /dev/null 2>/dev/null | grep -q "TLS" || (echo "❌ TLS 1.2+ not working" && exit 1)
	@echo "Checking for forbidden practices..."
	@! grep -r "tail -f" srcs/requirements/*/tools/ 2>/dev/null || (echo "❌ Found forbidden 'tail -f'" && exit 1)
	@! grep -r "sleep infinity" srcs/requirements/*/tools/ 2>/dev/null || (echo "❌ Found forbidden 'sleep infinity'" && exit 1)
	@echo "✅ Security checks passed"

.PHONY: check check-requirements check-containers check-services check-network check-volumes check-security
