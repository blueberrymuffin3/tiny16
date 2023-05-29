{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  # nativeBuildInputs is usually what you want -- tools you need to run
  nativeBuildInputs = [
    pkgs.gnumake
    (pkgs.fasmg.overrideAttrs (old: rec {
      pname = old.pname;
      version = "k0v2";

      src = pkgs.fetchzip {
        url = "https://flatassembler.net/fasmg.${version}.zip";
        sha256 = "sha256-STJ8Lj3BA5KyDr2+ekE0wwbsE+KkkDC3WDroN50xXRg=";
        stripRoot = false;
      };
    }))
    pkgs.rustup
    pkgs.xterm
    pkgs.python3

    # Verilog:
    # pkgs.verilog
    pkgs.verible
    pkgs.svls
    # pkgs.quartus-prime-lite
    (pkgs.callPackage ./t16vl/iverilog.nix { })
    (pkgs.callPackage ./t16vl/istyle.nix { })

    # Serial console:
    pkgs.python3Packages.pyserial
  ];

  shellHook = ''
    alias miniterm.py='python -m serial.tools.miniterm'
  '';
}
