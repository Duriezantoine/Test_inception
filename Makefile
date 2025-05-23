all:
	docker compose up --remove-orphans
down: 
	docker compose down
	docker container prune -f
	docker volume prune -f
	docker image prune -f -a
	docker network prune -f
	docker builder prune --all --force
	docker system prune --all --volumes --force
	sudo rm -rf web/
	sudo rm -rf db_data/

re: down all