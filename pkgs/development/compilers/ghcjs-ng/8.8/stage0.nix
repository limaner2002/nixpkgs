{ callPackage, configuredSrc }:

{

  ghcjs = callPackage
    ({ mkDerivation, aeson, alex, array, attoparsec, base, base16-bytestring
    , base64-bytestring, binary, bytestring, Cabal, containers
    , cryptohash, data-default, deepseq, directory, executable-path
    , filepath, ghc-boot, ghc-boot-th, ghc-compact, ghc-heap, ghc-paths
    , ghci, happy, hashable, hpc, http-types, HUnit, lens, lib
    , lifted-base, mtl, network, optparse-applicative, parallel, parsec
    , process, random, safe, shelly, split, stringsearch, syb, tar
    , template-haskell, terminfo, test-framework, test-framework-hunit
    , text, time, transformers, unix, unix-compat, unordered-containers
    , vector, wai, wai-app-static, wai-extra, wai-websockets, warp
    , webdriver, websockets, wl-pprint-text, xhtml, yaml
    }:
    mkDerivation {
      pname = "ghcjs";
      version = "8.8.0.0.1";
      src = configuredSrc + /.;
      isLibrary = true;
      isExecutable = true;
      libraryHaskellDepends = [
        aeson array attoparsec base base16-bytestring base64-bytestring
        binary bytestring Cabal containers cryptohash data-default deepseq
        directory filepath ghc-boot ghc-boot-th ghc-compact ghc-heap
        ghc-paths ghci hashable hpc lens mtl optparse-applicative parallel
        parsec process safe split stringsearch syb template-haskell
        terminfo text time transformers unix unordered-containers vector
        wl-pprint-text yaml
      ];
      libraryToolDepends = [ alex happy ];
      executableHaskellDepends = [
        aeson array base binary bytestring Cabal containers deepseq
        directory executable-path filepath ghc-boot lens mtl
        optparse-applicative parsec process tar terminfo text time
        transformers unix unix-compat unordered-containers vector xhtml
        yaml
      ];
      testHaskellDepends = [
        aeson base bytestring data-default deepseq directory filepath
        http-types HUnit lens lifted-base network optparse-applicative
        process random shelly test-framework test-framework-hunit text time
        transformers unordered-containers wai wai-app-static wai-extra
        wai-websockets warp webdriver websockets yaml
      ];
      description = "Haskell to JavaScript compiler";
      license = lib.licenses.mit;
    }) {};

}
