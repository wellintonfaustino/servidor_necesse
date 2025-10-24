# ===========================
# NECESSE DEDICATED SERVER
# Persistente + EasyPanel ready
# ===========================
FROM debian:bullseye-slim

# 🧑 Cria usuário não-root (melhor prática)
ARG user=necesse
ARG group=necesse
ARG uid=1000
ARG gid=1000

RUN groupadd -g ${gid} ${group} && \
    useradd -u ${uid} -g ${group} -s /bin/bash -m ${user}

# ⚙️ Instala dependências básicas + Java 17
RUN dpkg --add-architecture i386 && \
    apt update && \
    apt install -y lib32gcc-s1 curl openjdk-17-jre-headless ca-certificates-java && \
    rm -rf /var/lib/apt/lists/*

# 🕹️ Instala SteamCMD e baixa o servidor do Necesse
RUN mkdir -p /steamapps && \
    curl -sqL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar zxvf - -C /steamapps
WORKDIR /steamapps

RUN echo '@ShutdownOnFailedCommand 1' > update_necesse.txt && \
    echo '@NoPromptForPassword 1' >> update_necesse.txt && \
    echo 'force_install_dir /app/' >> update_necesse.txt && \
    echo 'login anonymous' >> update_necesse.txt && \
    echo 'app_update 1169370 validate' >> update_necesse.txt && \
    echo 'quit' >> update_necesse.txt && \
    ./steamcmd.sh +runscript update_necesse.txt

# 🔍 Corrige case do arquivo do servidor (server.jar → Server.jar)
RUN ls /app && mv /app/server.jar /app/Server.jar 2>/dev/null || true

# 📁 Garante que as pastas de save/logs existam e tenham dono
RUN mkdir -p /home/necesse/.config/Necesse/saves /home/necesse/.config/Necesse/logs && \
    chown -R ${uid}:${gid} /app /home/necesse

# 🧑 Alterna para o usuário seguro
USER ${uid}:${gid}
WORKDIR /app

# 🚀 Entrypoint do servidor
# Mantém compatibilidade com EasyPanel e evita reinicialização desnecessária
RUN echo '#!/bin/sh' > entrypoint.sh && \
    echo 'set -e' >> entrypoint.sh && \
    echo 'WORLD_NAME=${WORLD_NAME:-default}' >> entrypoint.sh && \
    echo 'SAVE_DIR=/home/necesse/.config/Necesse/saves/worlds' >> entrypoint.sh && \
    echo 'mkdir -p "$SAVE_DIR"' >> entrypoint.sh && \
    echo 'if [ ! -f "$SAVE_DIR/${WORLD_NAME}.zip" ]; then' >> entrypoint.sh && \
    echo '  echo "[INFO] Nenhum mundo existente encontrado, criando novo: ${WORLD_NAME}.zip"' >> entrypoint.sh && \
    echo 'else' >> entrypoint.sh && \
    echo '  echo "[INFO] Carregando mundo existente: ${WORLD_NAME}.zip"' >> entrypoint.sh && \
    echo 'fi' >> entrypoint.sh && \
    echo 'exec java -jar Server.jar -nogui -world "$WORLD_NAME"' >> entrypoint.sh && \
    chmod +x entrypoint.sh

# 🌐 Portas padrão (TCP + UDP)
EXPOSE 14159/tcp
EXPOSE 14159/udp

# 💾 Volume persistente — precisa ser montado externamente!
# Use EasyPanel → Volumes → /home/necesse/.config/Necesse/saves
VOLUME ["/home/necesse/.config/Necesse/saves"]

# 🔧 Variável padrão do mundo
ENV WORLD_NAME=default

# 🏁 Executa o servidor
CMD ["./entrypoint.sh"]
