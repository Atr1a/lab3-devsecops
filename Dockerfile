# Dockerfile (намеренно уязвимый) — версия "до исправления" из методички
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
