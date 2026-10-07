# Dockerfile (исправленный)
# - node:22-alpine вместо устаревшего node:18 (EOL), минимальный базовый образ
# - apk upgrade подтягивает исправленные пакеты ОС; если зеркало Alpine недоступно
#   (проблемы сети), шаг пропускается и сборка продолжается
# - после установки зависимостей удаляем npm/yarn/corepack: в рантайме они не нужны,
#   а их встроенные библиотеки — частый источник HIGH-уязвимостей
# - контейнер работает от непривилегированного пользователя node
FROM node:22-alpine
WORKDIR /app

RUN apk upgrade --no-cache || echo "WARNING: apk upgrade пропущен (зеркало Alpine недоступно)"

COPY package*.json ./
RUN npm install --omit=dev \
 && npm cache clean --force \
 && rm -rf /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/corepack \
           /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack \
           /usr/local/bin/yarn /usr/local/bin/yarnpkg /opt/yarn-*

COPY server.js .
USER node
EXPOSE 3000
CMD ["node", "server.js"]
