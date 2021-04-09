FROM node:14-alpine as source

LABEL authors="Albert Iblyaminov <rieset@yandex.ru>" \
      org.label-schema.vendor="Frontend Service" \
      org.label-schema.name="Frontend Service Image" \
      org.label-schema.description="Frontend  Service" \
      org.label-schema.url="https://site.ru" \
      org.label-schema.schema-version="1.0"

ENV BUILD_DEPS="" \
    RUNTIME_DEPS="" \
    NODE_ENV="production" \
    NODE_OPTIONS="--max_old_space_size=2048"

WORKDIR /home/app

RUN set -x && \
    apk add --update $RUNTIME_DEPS && \
    apk add --no-cache --virtual build_deps $BUILD_DEPS

COPY . .

RUN yarn install --production=false && \
    node_modules/.bin/ng build --prod && \
    node_modules/.bin/ng run desktop:server:production



# -----------
# Production image

FROM node:14-alpine

ENV NODE_ENV="production" \
    PORT="3000" \
    USER="app" \
    FRONTEND_INSTANCES="2" \
    FRONTEND_MEMORY="230M" \
    LABEL="Frontend"

WORKDIR /home/$USER

RUN npm install pm2 -g && \
    addgroup -g 2000 app && \
    adduser -u 2000 -G app -s /bin/sh -D app

USER $USER

COPY --chown=$USER:$USER --from=source ["/home/app/dist/", "/home/app/pm2.config.js", "/home/$USER/dist/"]

CMD ["pm2-runtime", "start", "./dist/pm2.config.js"]
