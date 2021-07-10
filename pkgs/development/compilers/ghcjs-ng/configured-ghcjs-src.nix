{ perl
, autoconf
, automake
, cabal2nix
, gnutar
, python3
, gcc
, cabal-install
, runCommand
, lib
, stdenv

, ghc
, happy
, alex

, ghcjsSrc
}:
stdenv.mkDerivation {
  src = ghcjsSrc;
  name = "configured-ghcjs-src";
  phases = [ "unpackPhase"
             "patchPhase"
             "configurePhase"
             "installPhase"
           ];

  # Apply the patch that fixes https://gitlab.haskell.org/ghc/ghc/-/issues/19655
  patches = [ ./8.8/ghc.patch
              ./8.8/ghcjs.patch
            ];

  configurePhase = ''
    export HOME=$(pwd)
    mkdir $HOME/.cabal
    touch $HOME/.cabal/config
    sed -i 's/RELEASE=NO/RELEASE=YES/' ghc/configure.ac &&

    patchShebangs . &&
    ./utils/makePackages.sh copy &&

    cabal2nix . > default.nix
  '';

  installPhase = ''
    mkdir $out
    cp -R * $out
  '';
  nativeBuildInputs = [
    alex
    autoconf
    automake
    cabal-install
    cabal2nix
    gcc
    ghc
    gnutar
    happy
    python3
  ];
}
# let stackPatch = ./8.8/stack.yaml.patch;
# in
# runCommand "configured-ghcjs-src" {
#   nativeBuildInputs = [
#     perl
#     autoconf
#     automake
#     python3
#     ghc
#     happy
#     alex
#     cabal-install
#   ] ++ lib.optionals stdenv.isDarwin [
#     gcc # https://github.com/ghcjs/ghcjs/issues/663
#   ];
#   inherit ghcjsSrc;
# } ''
#   export HOME=$(pwd)
#   mkdir $HOME/.cabal
#   touch $HOME/.cabal/config
#   cp -r "$ghcjsSrc" "$out"
#   chmod -R +w "$out"
#   cd "$out"

#   # TODO: Find a better way to avoid impure version numbers
#   sed -i 's/RELEASE=NO/RELEASE=YES/' ghc/configure.ac

#   # # TODO: How to actually fix this?
#   # # Seems to work fine and produce the right files.
#   # touch ghc/includes/ghcautoconf.h
#   mkdir -p ghc/compiler/vectorise
#   mkdir -p ghc/utils/haddock/haddock-library/vendor

#   patchShebangs .
#   ./utils/makePackages.sh copy
# ''
