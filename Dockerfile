# Use a base image
FROM debian:bullseye-slim

# Add user 'necesse', don't run stuff as root!!
ARG user=necesse
ARG group=necesse
ARG uid=1000
ARG gid=1000

RUN groupadd -g ${gid} ${group}
RUN useradd -u ${uid} -g ${group} -s /bin/bash -m ${user}

RUN dpkg --add-architecture i386
RUN apt update; apt install -y ca-certificates-java
RUN apt update; apt install -y lib32gcc-s1 curl openjdk-17-jre-headless

# Download and extract SteamCMD
RUN mkdir -p /steamapps
RUN curl -sqL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar zxvf - -C /steamapps
WORKDIR /steamapps

# Create the update_necesse.txt file
RUN echo '@ShutdownOnFailedCommand 1' >> update_necesse.txt \
    && echo '@NoPromptForPassword 1' >> update_necesse.txt \
    && echo 'force_install_dir /app/' >> update_necesse.txt \
    && echo 'login anonymous' >> update_necesse.txt \
    && echo 'app_update 1169370 validate' >> update_necesse.txt \
    && echo 'quit' >> update_necesse.txt

RUN echo $(date) && ./steamcmd.sh +runscript update_necesse.txt

# Saves will be available under /root/.config/Necesse/saves
RUN chown -R 1000:1000 /app
RUN mkdir -p /home/necesse/.config/Necesse
RUN chown -R 1000:1000 /home/necesse

USER ${uid}:${gid}

# Set the working directory and create entrypoint.sh
WORKDIR /app
RUN echo '#!/bin/sh' > entrypoint.sh && \
    echo 'java -jar Server.jar -nogui -world "$WORLD_NAME"' >> entrypoint.sh && \
    chmod +x entrypoint.sh

# Set the entry point for the container
CMD ["./entrypoint.sh"]