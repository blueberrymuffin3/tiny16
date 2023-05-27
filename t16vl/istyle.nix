{ stdenv
, lib
, fetchFromGitHub
}:

stdenv.mkDerivation {
  pname = "iStyle";
  version = "2022-1-27";

  src = fetchFromGitHub {
    owner = "thomasrussellmurphy";
    repo = "istyle-verilog-formatter";
    rev = "e368dee27811d0c891677fa40609e197c64de58c";
    sha256 = "sha256-y/4epQ2d4kSF/i4l4xPUiENED18wP3W61RgPLKoT1h4=";
  };

  installPhase = ''
    # $out is an automatically generated filepath by nix,
    # but it's up to you to make it what you need. We'll create a directory at
    # that filepath, then copy our sources into it.

    mkdir -p $out/bin
    cp bin/release/* $out/bin
  '';
}
