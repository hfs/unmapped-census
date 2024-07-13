FROM docker.io/debian:testing
LABEL maintainer="openstreetmap.org@knackich.de"

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get -y install --no-install-recommends unzip wget osm2pgsql \
        osmium-tool postgresql-client-16 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENTRYPOINT ["/bin/bash"]
