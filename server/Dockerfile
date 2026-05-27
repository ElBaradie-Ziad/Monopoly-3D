FROM ubuntu:22.04

RUN apt update && apt install -y \
    libssl-dev \
    g++ \
    cmake \
    make \
    pkg-config \
    libpqxx-dev \
    libpq-dev \
    ccache \
    mold \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# On pré-génère les clés pour ne pas le refaire à chaque build de code
RUN openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=FR/ST=GrandEst/L=Strasbourg/O=Monopoly/CN=localhost" \
    -keyout server.key -out server.crt

COPY . .

# Désactivation de ASAN dans Docker pour économiser RAM/CPU sauf si demandé
# Utilisation de PCH + Mold (installés plus haut)
RUN cmake -S . -B build -DUSE_ASAN=OFF
RUN cmake --build build --target MonopolyServer -j$(nproc)

CMD ["./build/MonopolyServer"]
