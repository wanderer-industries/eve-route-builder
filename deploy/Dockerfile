FROM golang:1.25.4-alpine AS sde-converter-builder

ARG WANDERER_ASSETS_REF=9229576a93e4cd203d3017c705e328c4bb34bbda

RUN apk add --no-cache git
RUN git init /src/wanderer-assets \
    && cd /src/wanderer-assets \
    && git remote add origin https://github.com/wanderer-industries/wanderer-assets.git \
    && git fetch --depth 1 origin "${WANDERER_ASSETS_REF}" \
    && git checkout --detach FETCH_HEAD

WORKDIR /src/wanderer-assets/wanderer-sde

RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/sdeconvert ./cmd/sdeconvert

FROM node:16-alpine

WORKDIR /usr/src/app

COPY --from=sde-converter-builder /out/sdeconvert /usr/local/bin/sdeconvert

COPY package.json package-lock.json ./
COPY . .

CMD ["sh", "./deploy/run-install.sh"]
