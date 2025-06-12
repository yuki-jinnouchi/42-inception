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
