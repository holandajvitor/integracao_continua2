FROM golang:1.22 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o /app/bin/server .

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && curl -fsSL https://go.dev/dl/go1.23.6.linux-amd64.tar.gz -o /tmp/go.tar.gz \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/bin/server .
COPY assets ./assets
COPY templates ./templates
COPY go.mod go.sum ./
COPY main.go ./
COPY main_test.go ./
COPY controllers ./controllers
COPY database ./database
COPY models ./models
COPY routes ./routes

ENV DB_HOST=postgres \
    DB_USER=root \
    DB_PASSWORD=root \
    DB_NAME=root \
    DB_PORT=5432 \
    PATH="/usr/local/go/bin:$PATH"

EXPOSE 8080

CMD ["./server"]
