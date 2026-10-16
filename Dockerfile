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

FROM node:18-alpine

# Set necessary environment variables.
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global \
    PATH=$PATH:/home/node/.npm-global/bin:/home/node/node_modules/.bin:$PATH

# For handling Kernel signals properly
RUN apk add --no-cache tini

# Create the working directory, including the node_modules folder for the sake of assigning ownership in the next command
RUN mkdir -p /usr/src/app/node_modules

# Change ownership of the working directory to the node:node user:group
# This ensures that npm install can be executed successfully with the correct permissions
RUN chown -R node:node /usr/src/app

# Set the user to use when running this image
# Non previlage mode for better security (this user comes with official NodeJS image).
USER node

# Set the default working directory for the app
# It is a best practice to use the /usr/src/app directory
WORKDIR /usr/src/app

COPY --from=sde-converter-builder --chown=node:node /out/sdeconvert /tmp/sdeconvert

# Copy package.json, package-lock.json
# Copying this separately prevents re-running npm install on every code change.
COPY --chown=node:node package*.json ./

# Install dependencies.
# RUN npm i -g @nestjs/cli
RUN npm install

# Necessary to run before adding application code to leverage Docker cache
RUN npm cache clean --force

# Bundle app source
COPY --chown=node:node . ./

ARG SDE_BUILD_ID=local

RUN set -eu; \
    echo "Generating route graph for SDE build ${SDE_BUILD_ID}"; \
    sde_output_dir="$(mktemp -d)"; \
    /tmp/sdeconvert --download --format csv --output "$sde_output_dir"; \
    mkdir -p ./eveData; \
    cp "$sde_output_dir/mapSolarSystems.csv" ./eveData/mapSolarSystems.csv; \
    cp "$sde_output_dir/mapSolarSystemJumps.csv" ./eveData/mapSolarSystemJumps.csv; \
    npm run generateGraph; \
    rm -rf "$sde_output_dir" ./eveData /tmp/sdeconvert

RUN npm run build
RUN npm prune --production

RUN chown -R node:node /usr/src/app

EXPOSE 2001

ENTRYPOINT ["/sbin/tini", "--"]

# Run the web service on container startup
CMD [ "npm", "run", "start:prod" ]
