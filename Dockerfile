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
FROM public.ecr.aws/amazonlinux/amazonlinux:minimal

# Install ca-certificates if needed
RUN dnf update -y && dnf install -y ca-certificates && dnf clean all

WORKDIR /app

# Copy our build
COPY --from=builder /app/target/release/nitro-auth /app/nitro-auth

RUN chmod +x /app/nitro-auth

# Set the RUST_LOG environment variable to INFO
ENV RUST_LOG=info

CMD ["/app/nitro-auth"]