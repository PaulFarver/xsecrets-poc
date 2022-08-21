FROM node:16.14.2-alpine as winxp

WORKDIR /app
COPY winXP .
RUN yarn install
RUN yarn build

FROM nginx:1.23-alpine

COPY static /usr/share/nginx/html
COPY config /etc/nginx

COPY --from=winxp /app/build /usr/share/nginx/html/secret