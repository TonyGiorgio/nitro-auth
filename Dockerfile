####################################################################################################
## Builder
####################################################################################################
FROM docker.io/library/rust:latest AS builder

RUN update-ca-certificates

WORKDIR /app

COPY ./ .

# Build for the default target
RUN cargo build --release

####################################################################################################
## Final image
####################################################################################################
FROM docker.io/library/ubuntu:20.04

RUN apt-get update && apt-get install -y ca-certificates

WORKDIR /app

# Copy our build
COPY --from=builder /app/target/release/nitro-auth /app/nitro-auth

RUN chmod +x /app/nitro-auth

CMD ["/app/nitro-auth"]