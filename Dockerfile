FROM node:22-alpine
WORKDIR /app
COPY package.json ./
COPY shared ./shared
COPY services ./services
COPY web ./web
ENV HOST=0.0.0.0
CMD ["node", "services/gateway/server.mjs"]
