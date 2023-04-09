{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };
  outputs = { nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };
      pint = (with pkgs; python39Packages.buildPythonPackage rec {
        name = "pint";
        version = "0.7.2";

        disabled = python39Packages.pythonOlder "3.6";

        src = fetchPypi {
          pname = "Pint";
          inherit version;
          hash = "sha256-OLl9NSpjdrtOlXCVyLdcHCqo7b+afM8FjWmxR4Yud60=";
        };

        nativeBuildInputs = [ python39Packages.setuptools-scm ];

        propagatedBuildInputs = [ python39Packages.packaging ]
          ++ lib.optionals (python39Packages.pythonOlder "3.8") [ python39Packages.importlib-metadata ];

        doCheck = false;

        dontUseSetuptoolsCheck = true;
      });
      obd = (with pkgs; python39Packages.buildPythonPackage rec {
        name = "obd";
        version = "0.7.1";
        src = fetchPypi {
          pname = name;
          inherit version;
          sha256 = "sha256-i4HqWJYVe26GGvEuFzwQsAHLbMpuuwTbLAHTJoEq13s=";
        };
        propagatedBuildInputs = [ pint python39Packages.pyserial ];
        doCheck = false;
      });
      ELM327-emulator = (with pkgs; python39Packages.buildPythonPackage rec {
        name = "ELM327-emulator";
        version = "3.0.0";
        src = ./.;
        propagatedBuildInputs = [ pint obd python39Packages.pyserial python39Packages.python-daemon python39Packages.pyyaml ];
      });
    in
    rec {
      defaultApp = flake-utils.lib.mkApp {
        drv = defaultPackage;
      };
      defaultPackage = ELM327-emulator;
      devShell = pkgs.mkShell {
        buildInputs = [
          ELM327-emulator
        ];
      };
    }
  );
}
