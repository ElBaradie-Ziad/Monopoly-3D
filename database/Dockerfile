FROM ubuntu:22.04

RUN apt update && apt install -y \
    g++ \
    cmake \
    make \
    pkg-config \
    libpqxx-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

RUN cmake -S server -B build -DBUILD_TESTS=ON
RUN cmake --build build

CMD ["./build/MonopolyServer"]