{ configuredSrc, mkDerivation, xorg, rts, lib, ghcjs }:
mkDerivation {
  pname = "ghc-prim";
  version = "0.5.3";
  sha256 = "07s75s4yj33p87zzpvp68hgf72xsxg6rm47g4aaymmlf52aywmv9";
  libraryHaskellDepends = [ rts ];
  buildDepends = [ ghcjs xorg.lndir ];
  configureFlags = [ "--ghcjs" ];
  description = "GHC primitives";
  license = lib.licenses.bsd3;
  src = configuredSrc;

  prePatch = ''
    mkdir -p lib/boot/compiler
    ln -s $(pwd)/lib/boot/data lib/boot/compiler/prelude

    mkdir -p lib/boot/utils
    ln -s $(pwd)/ghc/inplace/bin lib/boot/utils/genprimopcode

    cd lib/boot/pkg/ghc-prim
  '';

}
