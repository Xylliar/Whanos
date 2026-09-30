COMPOSE := docker compose

.PHONY: all install up down clean re logs kubeconfig

all: up

install:
	@if ! command -v docker > /dev/null; then \
		curl -fsSL https://get.docker.com -o get-docker.sh && \
		sudo sh get-docker.sh && \
		rm -f get-docker.sh && \
		sudo systemctl enable --now docker && \
		sudo usermod -aG docker $$USER; \
	else \
		echo "Docker is already installed, skipping Docker installation."; \
	fi

.env:
	@echo "Missing .env file: copy .env.example to .env and fill it in." >&2
	@exit 1

up: .env
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down -v --rmi local

re: clean up

logs:
	$(COMPOSE) logs -f

kubeconfig:
	$(COMPOSE) exec k3s-server cat /output/kubeconfig.yaml > k3s.yaml
	@echo "Use it with: KUBECONFIG=k3s.yaml kubectl get nodes"
