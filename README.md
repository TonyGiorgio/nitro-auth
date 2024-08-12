# Nitro Auth

This project builds a Rust application and packages it into a Docker container, which can then be converted into an AWS Nitro Enclave image.

## Prerequisites

- Nix package manager
- AWS CLI configured with appropriate credentials
- An EC2 instance that supports AWS Nitro Enclaves (for running the enclave)
- nitro-cli (installed separately)

## Building and Running

1. Enter the Nix development environment:

   ```bash
   nix develop
   ```

2. Install nitro-cli (if not already installed):
   
   Follow the instructions in the [AWS Nitro Enclaves CLI documentation](https://docs.aws.amazon.com/enclaves/latest/user/nitro-enclave-cli-install.html) to install nitro-cli on your system.

3. Build the Docker image:

   ```bash
   docker build -t nitro-auth .
   ```

4. Convert the Docker image to an AWS Nitro Enclave image:

   ```bash
   nitro-cli build-enclave --docker-uri nitro-auth:latest --output-file nitro-auth.eif
   ```

   This will create a file named `nitro-auth.eif` in your current directory.

5. To run the enclave (on a supported EC2 instance):

   ```bash
   nitro-cli run-enclave --eif-path nitro-auth.eif --memory 512 --cpu-count 2
   ```

   Adjust the memory and CPU count as needed for your application.

6. To stop and destroy the enclave:
   
   a. List running enclaves to get the enclave ID:
   ```bash
   nitro-cli describe-enclaves
   ```

   b. Stop the enclave using its ID:
   ```bash
   nitro-cli terminate-enclave --enclave-id <enclave-id>
   ```
   Replace `<enclave-id>` with the actual ID of your running enclave.

   c. Verify that the enclave has been terminated:
   ```bash
   nitro-cli describe-enclaves
   ```
   This should show no running enclaves if the termination was successful.

   d. Remove the Nitro Enclave image file:
   ```bash
   rm nitro-auth.eif
   ```

   e. Optionally, remove the Docker image if you no longer need it:
   ```bash
   docker rmi nitro-auth:latest
   docker rmi localhost/nitro-auth:latest
   ```

   These steps ensure that your enclave is properly stopped, destroyed, and all associated resources are cleaned up.

## Development

The project uses a `flake.nix` for dependency management and development environment setup. The `flake.nix` file includes:

- Rust toolchain
- AWS CLI
- Podman (aliased as Docker)

To make changes to the development environment, edit the `flake.nix` file and re-enter the Nix shell.

## Dockerfile

The Dockerfile uses a multi-stage build:

1. It starts with a Rust base image to build the application.
2. The final image is based on Ubuntu 20.04 and includes only the necessary runtime dependencies.

To modify the build process or add dependencies, edit the Dockerfile.

## Notes

- The Docker build process is actually using Podman, which is aliased to the `docker` command in the Nix environment.
- Ensure you have the necessary AWS permissions to create and manage Nitro Enclaves.
- The Nitro Enclave image (.eif) can only be run on EC2 instances that support AWS Nitro Enclaves.
- `nitro-cli` is not included in the Nix environment and needs to be installed separately.

## Uploading and Running the Docker Image on an EC2 Instance

After building the Docker image, follow these steps to upload and run it on your EC2 instance:

1. Save the Docker image as a tar file:
   ```bash
   docker save nitro-auth:latest > nitro-auth.tar
   ```

2. Upload the tar file to your EC2 instance:
   ```bash
   scp -i /path/to/your-key.pem nitro-auth.tar ec2-user@your-ec2-instance-ip:/home/ec2-user/
   ```
   Replace `/path/to/your-key.pem`, `ec2-user`, and `your-ec2-instance-ip` with your specific details.

3. SSH into your EC2 instance:
   ```bash
   ssh -i /path/to/your-key.pem ec2-user@your-ec2-instance-ip
   ```

4. Load the Docker image on the EC2 instance:
   ```bash
   docker load < nitro-auth.tar
   ```

5. Tag the loaded image:
   ```bash
   docker tag localhost/nitro-auth:latest nitro-auth:latest
   ```

6. Verify that the image is correctly tagged:
   ```bash
   docker images
   ```
   You should see both `localhost/nitro-auth` and `nitro-auth` with the `latest` tag.

7. Build the Nitro Enclave image:
   ```bash
   nitro-cli build-enclave --docker-uri nitro-auth:latest --output-file nitro-auth.eif
   ```
   This will create a file named `nitro-auth.eif` in your current directory.

8. To run the enclave on the EC2 instance:
   ```bash
   nitro-cli run-enclave --eif-path nitro-auth.eif --memory 512 --cpu-count 2
   ```
   Adjust the memory and CPU count as needed for your application.

These steps ensure that your Docker image is properly loaded, tagged, and converted into a Nitro Enclave image on your EC2 instance.