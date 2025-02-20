FROM python:3.11-bullseye
LABEL org.opencontainers.image.source https://github.com/Atflow-Corp/docker

RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        unzip awscli jq \
        # for opencv
        libgl1-mesa-glx libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install docker for deployment
RUN curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && rm -fv get-docker.sh
