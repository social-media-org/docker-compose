# Remplace le Dockerfile amont : son image python:3.11-slim-bullseye (Debian 11, fin de vie)
# échoue à l'apt-get (404 sur bullseye-security). Contexte de build = clone amont.
FROM python:3.11-slim-bookworm

WORKDIR /MoneyPrinterTurbo
ENV PYTHONPATH="/MoneyPrinterTurbo"

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN pip install --no-cache-dir --retries 3 --timeout 60 -r requirements.txt

COPY . .
EXPOSE 8501
