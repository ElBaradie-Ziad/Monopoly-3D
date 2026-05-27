# docker
up:
	docker compose up -d

down:
	docker compose down

reset:
	docker compose down -v
	docker compose up -d

logs:
	docker compose logs -f

db:
	docker exec -it monopoly-db psql -U monopoly -d monopoly3d

# Options
JOBS ?= $(shell nproc)
CMAKE_OPTS ?= -DUSE_ASAN=OFF

# Server / Project Build
all:
	mkdir -p build && cd build && cmake .. $(CMAKE_OPTS) && make all -j$(JOBS)

server:
	mkdir -p build && cd build && cmake .. $(CMAKE_OPTS) && make server -j$(JOBS)

test:
	mkdir -p build && cd build && cmake .. $(CMAKE_OPTS) -DUSE_TEST_MODE=ON && make test -j$(JOBS)

tests:
	mkdir -p build && cd build && cmake .. $(CMAKE_OPTS) -DUSE_TEST_MODE=ON && make MonopolyTests -j$(JOBS)
	cd build && ./MonopolyTests

build: all

run: server
	openssl req -newkey rsa:2048 -nodes -keyout server.key -x509 -days 365 -out server.crt -subj "/C=FR/ST=GrandEst/L=Strasbourg/O=Monopoly/CN=localhost" || true
	LSAN_OPTIONS=suppressions=$(CURDIR)/asan.supp DB_HOST=localhost DB_PORT=5433 ./build/MonopolyServer

clean:
	rm -rf build
