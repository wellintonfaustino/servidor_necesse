FROM debian:bullseye-slim

ARG user=necesse
ARG group=necesse
ARG uid=1000
ARG gid=1000

RUN groupadd -g ${gid} ${group} && \
    useradd -u ${uid} -g ${group} -s /bin/bash -m ${user}

RUN dpkg --add-architecture i386 && \
    apt update && \
    apt install -y lib32gcc-s1 curl openjdk-17-jre-headless ca-certificates-java && \
    rm -rf /var/lib/apt/lists/*

# SteamCMD setup
RUN mkdir -p /steamapps && \
    curl -sqL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar zxvf - -C /steamapps
WORKDIR /steamapps

RUN echo '@ShutdownOnFailedCommand 1' >> update_necesse.txt && \
    echo '@NoPromptForPassword 1' >> update_necesse.txt && \
    echo 'force_install_dir /app/' >> update_necesse.txt && \
    echo 'login anonymous' >> update_necesse.txt && \
    echo 'app_update 1169370 validate' >> update_necesse.txt && \
    echo 'quit' >> update_necesse.txt && \
    ./steamcmd.sh +runscript update_necesse.txt

RUN ls /app && mv /app/server.jar /app/Server.jar 2>/dev/null || true

RUN mkdir -p /home/necesse/.config/Necesse/saves && \
    chown -R ${uid}:${gid} /app /home/necesse

USER ${uid}:${gid}
WORKDIR /app

# Entrypoint
RUN echo '#!/bin/sh' > entrypoint.sh && \
    echo 'WORLD_NAME=${WORLD_NAME:-default}' >> entrypoint.sh && \
    echo 'java -jar Server.jar -nogui -world "$WORLD_NAME"' >> entrypoint.sh && \
    chmod +x entrypoint.sh

EXPOSE 14159/tcp
EXPOSE 14159/udp
VOLUME ["/home/necesse/.config/Necesse/saves"]

ENV WORLD_NAME=default
CMD ["./entrypoint.sh"]
