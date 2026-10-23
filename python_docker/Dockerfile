ARG PYTHON_VERSION=3.13.17
ARG PYTHON_VARIANT=bookworm
FROM python:${PYTHON_VERSION}-${PYTHON_VARIANT}
LABEL org.opencontainers.image.source="https://github.com/Atflow-Corp/docker"

RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates unzip awscli jq \
        # for opencv
        libgl1-mesa-glx libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install docker for deployment
RUN curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && rm -fv get-docker.sh

# AWS CLI's vendored botocore bundle otherwise keeps trusting the AAA cross-signs.
RUN ln -sf /etc/ssl/certs/ca-certificates.crt /usr/lib/python3/dist-packages/awscli/botocore/cacert.pem
