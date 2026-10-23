ARG PYTHON_VERSION=3.13
ARG PYTHON_VARIANT=bookworm
FROM python:${PYTHON_VERSION}-${PYTHON_VARIANT}
LABEL org.opencontainers.image.source="https://github.com/Atflow-Corp/docker"

# Verify the bootstrap download even when the base image has an outdated CA store.
RUN python -m pip install --no-cache-dir --require-hashes \
    "https://files.pythonhosted.org/packages/3f/06/3e4420302363fbb71be3c7f35ce042f54bfca330e3e66b3a2e3c4cca579f/pip-26.2.2-py3-none-any.whl#sha256=fd7f4dfa8190e014013b9f08f3e973f4e4c26ffd179a204895533a7254813a70"

RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates unzip awscli jq \
        # for opencv
        libgl1-mesa-glx libglib2.0-0 \
    # Keep both the bundle and hashed CA directory safe, including on older bases.
    && sed -i \
        -e 's|^mozilla/emSign_ECC_Root_CA_-_G3.crt$|!&|' \
        -e 's|^mozilla/Comodo_AAA_Services_root.crt$|!&|' \
        /etc/ca-certificates.conf \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install docker for deployment
RUN curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && rm -fv get-docker.sh

# AWS CLI's vendored botocore bundle otherwise keeps trusting the AAA cross-signs.
RUN ln -sf /etc/ssl/certs/ca-certificates.crt /usr/lib/python3/dist-packages/awscli/botocore/cacert.pem
