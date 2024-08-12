{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        craneLib = (crane.mkLib nixpkgs.legacyPackages.${system});
        myCrate = craneLib.buildPackage {
          src = craneLib.cleanCargoSource (craneLib.path ./.);
          name = "myCrate-${system}";
          buildInputs = [
            pkgs.awscli2
            pkgs.openssl
            pkgs.zlib
            pkgs.gcc
            pkgs.jq
          ];
        };

      in
      {
        packages.default = myCrate;

        devShells.default = pkgs.mkShell rec {
          inputsFrom = [ myCrate ];
          shellHook = ''
            export LD_LIBRARY_PATH=${pkgs.openssl}/lib:$LD_LIBRARY_PATH
            export RUST_LOG=info
            
            alias docker='podman'
            echo "Using 'podman' as an alias for 'docker'"
            echo "You can now use 'docker' commands, which will be executed by podman"

            # Podman configuration
            export CONTAINERS_CONF=$HOME/.config/containers/containers.conf
            export CONTAINERS_POLICY=$HOME/.config/containers/policy.json
            mkdir -p $HOME/.config/containers
            echo '{"default":[{"type":"insecureAcceptAnything"}]}' > $CONTAINERS_POLICY
            
            # Create a basic containers.conf if it doesn't exist
            if [ ! -f $CONTAINERS_CONF ]; then
              echo "[engine]
            cgroup_manager = \"cgroupfs\"
            events_logger = \"file\"
            runtime = \"crun\"" > $CONTAINERS_CONF
            fi

            # Ensure correct permissions
            chmod 600 $CONTAINERS_POLICY $CONTAINERS_CONF

            # Set up AWS CLI path
            export PATH=${pkgs.awscli2}/bin:$PATH

            echo "Note: nitro-cli is not included in this environment."
            echo "Please install it separately if needed for AWS Nitro Enclaves."
          '';
          buildInputs = [
            pkgs.awscli2
            pkgs.openssl
            pkgs.zlib
            pkgs.gcc
            pkgs.jq
            pkgs.podman
            pkgs.runc
            pkgs.conmon
            pkgs.slirp4netns
            pkgs.fuse-overlayfs
          ];
        };
      });
}
