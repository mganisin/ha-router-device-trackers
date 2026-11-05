FROM ghcr.io/astral-sh/uv:latest AS uv_bin

FROM python:3.12-slim AS builder
WORKDIR /app

COPY --from=uv_bin /uv /uv/bin/uv
ENV PATH="/uv/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml .
RUN uv pip install --system --no-cache robyn aiomqtt

FROM python:3.12-slim
WORKDIR /app

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin/robyn /usr/local/bin/robyn

COPY main.py .

USER nobody

ENV MQTT_BROKER=mqtt.local \
    MQTT_PORT=1883

EXPOSE 5000

CMD ["python", "main.py"]
