FROM rocker/r-ver:4.5.2
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git make cmake pkg-config libcurl4-openssl-dev libssl-dev libxml2-dev libuv1-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY scripts/install.R scripts/install.R
RUN Rscript --vanilla scripts/install.R
COPY R R
RUN useradd --create-home --uid 10001 mcp && chown -R mcp:mcp /app
USER mcp
ENV PORT=8080
EXPOSE 8080
CMD ["Rscript", "--vanilla", "R/server.R"]
