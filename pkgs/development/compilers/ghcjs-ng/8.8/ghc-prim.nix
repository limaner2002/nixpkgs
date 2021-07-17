{ configuredSrc, mkDerivation, rts, lib }:
mkDerivation {
  pname = "ghc-prim";
  version = "0.5.3";
  sha256 = "07s75s4yj33p87zzpvp68hgf72xsxg6rm47g4aaymmlf52aywmv9";
  libraryHaskellDepends = [ rts ];
  description = "GHC primitives";
  license = lib.licenses.bsd3;
  src = configuredSrc + /lib/boot/pkg/ghc-prim;
}
