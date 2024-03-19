# syntax=docker/dockerfile:1

ARG NODE_VERSION=20.11.0
ARG PNPM_VERSION=8.15.3

################################################################################
# Use node image for base image for all stages.
FROM node:${NODE_VERSION}-alpine as base

# Set working directory for all build stages.
WORKDIR /usr/src/app

# Install pnpm.
RUN --mount=type=cache,target=/root/.npm \
    npm install -g pnpm@${PNPM_VERSION}

################################################################################
# Create a stage for building the application.
FROM base as build-deps

# Download additional development dependencies before building, as some projects require
# "devDependencies" to be installed to build. If you don't need this, remove this step.
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=pnpm-lock.yaml,target=pnpm-lock.yaml \
    --mount=type=cache,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile

# Copy the rest of the source files into the image.
COPY . .
# Run the build script.
RUN pnpm run build

################################################################################
# Create a stage for installing production dependencies.
FROM base as deps

RUN --mount=type=bind,from=build-deps,source=/usr/src/app/build/package.json,target=package.json \
    --mount=type=bind,from=build-deps,source=/usr/src/app/build/pnpm-lock.yaml,target=pnpm-lock.yaml \
    --mount=type=cache,target=/root/.local/share/pnpm/store \
    pnpm install --prod --frozen-lockfile

################################################################################
# Create a new stage to run the application with minimal runtime dependencies
# where the necessary files are copied from the build stage.
FROM base as final

# Use production node environment by default.
ENV NODE_ENV production

# Run the application as a non-root user.
USER node

# Copy the production dependencies from the deps stage and also
# the built application from the build stage into the image.
COPY --from=build-deps /usr/src/app/build .
COPY --from=deps /usr/src/app/node_modules ./node_modules

# Expose the port that the application listens on.
EXPOSE 3333

# Run the application.
CMD node bin/server.js
