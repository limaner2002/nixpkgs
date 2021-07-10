{ stdenv
, pkgsHostHost
, callPackage
, emscripten
, fetchgit
, ghcjsSrcJson ? null
, ghcjsSrc ? fetchgit (builtins.fromJSON (builtins.readFile ghcjsSrcJson))
, bootPkgs
, stage0
, haskellLib
, cabal-install
, nodejs
, makeWrapper
, xorg
, gmp
, pkg-config
, gcc
, lib
, ghcjsDepOverrides ? (_:_:{})
, haskell
}:
# Last Failure:
# nix log /nix/store/l8izrpg6j7cjwl7z7xfl7swxlp8mpp88-ghcjs.drv
let configuredSrc = callPackage ./configured-ghcjs-src.nix {
        inherit ghcjsSrc;
        inherit (bootPkgs) ghc alex happy;
      };
      boot = bootPkgs.extend (lib.foldr lib.composeExtensions (_:_:{}) [
        (hself: _:
          { ghcjs =
              let base = hself.callPackage "${configuredSrc}" { };
              in base.overrideAttrs (_:
                { nativeBuildInputs = [ hself.alex
                                        hself.happy
                                      ];
                });
            ghcjs-boot = haskellLib.setBuildTarget ghcjs "ghcjs-boot";
              # let base = hself.callPackage "${configuredSrc}" { };
              # in base.overrideAttrs (oldAttrs:
              #   { nativeBuildInputs = [ hself.alex
              #                           hself.happy
              #                         ];
              #     buildInputs = oldAttrs.buildInputs
              #                   ++ [ hself.cabal-install
              #                        emscripten
              #                        nodejs
              #                      ];
              #     postBuild = ''
              #       echo "Running postBuild"
              #       ./dist/build/ghcjs-boot/ghcjs-boot -s ./lib/boot
              #     '';
              #     postInstall = ''
              #       echo "Running postInstall"
              #       cp ghc/settings $out/lib
              #       cp ./lib/boot/* $out/lib
              #     '';
              #   }
              # );
          })
        (callPackage ./common-overrides.nix {
          inherit haskellLib;
        })
        ghcjsDepOverrides
      ]);
      ghcjs = boot.ghcjs;
      ghcjs-boot = boot.ghcjs-boot;
      devShell = boot.shellFor
        { packages = hp: [ hp.ghcjs
                         ];
          buildInputs = [ boot.cabal-install
                          emscripten
                          nodejs
                        ];
        };
      bootDrv = stdenv.mkDerivation {
        name = "ghcjs";
        src = configuredSrc;
        phases = [ "unpackPhase"
                   "patchPhase"
                   "buildPhase"
                 ];
        patches = ./8.8/ghc-prim.patch;
        buildPhase = ''

          export HOME=$TMP
          mkdir $HOME/.cabal
          touch $HOME/.cabal/config

          echo "****************************************** $out ******************************************"

          mkdir -p $out/bin
          mkdir -p $out/lib/bin
          mkdir -p $out/lib/${bootGhcjs.name}/bin

          cp ${ghcjs}/bin/* $out/bin
          lndir ${ghcjs}/lib/${boot.ghc.name} $out/lib/${bootGhcjs.name}
          lndir ${boot.ghc}/lib/${boot.ghc.name} $out/lib/${bootGhcjs.name}
          # cp ${boot.ghc}/lib/${boot.ghc.name}/settings $out/lib/${bootGhcjs.name}
          # cp ${boot.ghc}/lib/${boot.ghc.name}/platformConstants $out/lib/${bootGhcjs.name}
          # cp ${boot.ghc}/lib/${boot.ghc.name}/llvm-passes $out/lib/${bootGhcjs.name}
          # cp ${boot.ghc}/lib/${boot.ghc.name}/llvm-targets $out/lib/${bootGhcjs.name}
          

          wrapProgram $out/bin/ghcjs --add-flags "-B$out/lib/${bootGhcjs.name}"
          wrapProgram $out/bin/ghcjs-pkg --add-flags "--global-package-db=$out/lib/${bootGhcjs.name}/package.conf.d"

          env PATH=$out/bin$PATH $out/bin/ghcjs-boot --with-ghc $out/bin/ghcjs --with-ghc-pkg $out/bin/ghcjs-pkg -s ./lib/boot
        '';
        buildInputs = [ ghcjs
                        boot.ghc
                        boot.cabal-install
                        emscripten
                        nodejs
                        makeWrapper
                        xorg.lndir
                      ];
      };
  # From the old version
  passthru = {
    configuredSrc = callPackage ./configured-ghcjs-src.nix {
      inherit ghcjsSrc;
      inherit (bootPkgs) ghc alex happy;
    };
    genStage0 = callPackage ./mk-stage0.nix { inherit (passthru) configuredSrc;  };
    bootPkgs = bootPkgs.extend (lib.foldr lib.composeExtensions (_:_:{}) [
      (self: _: import stage0 {
        inherit (passthru) configuredSrc;
        inherit (self) callPackage;
      })

      (callPackage ./common-overrides.nix {
        inherit haskellLib;
      })
      ghcjsDepOverrides
    ]);

    targetPrefix = "";
    inherit bootGhcjs;
    inherit (bootGhcjs) version;
    ghcVersion = bootPkgs.ghc.version;
    isGhcjs = true;

    enableShared = true;

    socket-io = pkgsHostHost.nodePackages."socket.io";

    # Relics of the old GHCJS build system
    stage1Packages = [];
    mkStage2 = { callPackage }: {
      # https://github.com/ghcjs/ghcjs-base/issues/110
      # https://github.com/ghcjs/ghcjs-base/pull/111
      ghcjs-base = haskell.lib.dontCheck (haskell.lib.doJailbreak (callPackage ./ghcjs-base.nix {}));
    };

    haskellCompilerName = "ghcjs-${bootGhcjs.version}";
  };

  bootGhcjs = haskellLib.justStaticExecutables passthru.bootPkgs.ghcjs;

in
{ inherit boot bootDrv configuredSrc devShell ghcjs ghcjs-boot bootGhcjs;
}

# let
#   passthru = {
#     configuredSrc = callPackage ./configured-ghcjs-src.nix {
#       inherit ghcjsSrc;
#       inherit (bootPkgs) ghc alex happy;
#     };
#     genStage0 = callPackage ./mk-stage0.nix { inherit (passthru) configuredSrc;  };
#     bootPkgs = bootPkgs.extend (lib.foldr lib.composeExtensions (_:_:{}) [
#       (self: _: import stage0 {
#         inherit (passthru) configuredSrc;
#         inherit (self) callPackage;
#       })

#       (callPackage ./common-overrides.nix {
#         inherit haskellLib;
#       })
#       ghcjsDepOverrides
#     ]);

#     targetPrefix = "";
#     inherit bootGhcjs;
#     inherit (bootGhcjs) version;
#     ghcVersion = bootPkgs.ghc.version;
#     isGhcjs = true;

#     enableShared = true;

#     socket-io = pkgsHostHost.nodePackages."socket.io";

#     # Relics of the old GHCJS build system
#     stage1Packages = [];
#     mkStage2 = { callPackage }: {
#       # https://github.com/ghcjs/ghcjs-base/issues/110
#       # https://github.com/ghcjs/ghcjs-base/pull/111
#       ghcjs-base = haskell.lib.dontCheck (haskell.lib.doJailbreak (callPackage ./ghcjs-base.nix {}));
#     };

#     haskellCompilerName = "ghcjs-${bootGhcjs.version}";
#   };

#   bootGhcjs = haskellLib.justStaticExecutables passthru.bootPkgs.ghcjs;
#   libexec = "${bootGhcjs}/libexec/${builtins.replaceStrings ["darwin" "i686"] ["osx" "i386"] stdenv.buildPlatform.system}-${passthru.bootPkgs.ghc.name}/${bootGhcjs.name}";

#   bootDrv = stdenv.mkDerivation {
#     name = bootGhcjs.name;
#     src = passthru.configuredSrc;
#     nativeBuildInputs = [
#       bootGhcjs
#       passthru.bootPkgs.ghc
#       cabal-install
#       emscripten
#       nodejs
#       makeWrapper
#       xorg.lndir
#       gmp
#       pkg-config
#     ] ++ lib.optionals stdenv.isDarwin [
#       gcc # https://github.com/ghcjs/ghcjs/issues/663
#     ];
#     dontConfigure = true;
#     dontInstall = true;
#     buildPhase = ''
#       mkdir -p $out/bin
#       cd lib/boot

#       ln -s ${bootGhcjs}/bin/ghcjs $out/bin
#       wrapProgram $out/bin/ghcjs --add-flags "-B$out/lib/${bootGhcjs.name}"

#       ghcjs-boot --with-ghc $out/bin
#     '';
# #     buildPhase = ''
# #       export HOME=$TMP
# #       mkdir $HOME/.cabal
# #       touch $HOME/.cabal/config
# #       cd lib/boot

# #       mkdir -p $out/bin
# #       mkdir -p $out/lib/${bootGhcjs.name}
# # #       lndir ${libexec} $out/bin

# #       wrapProgram $out/bin/ghcjs --add-flags "-B$out/lib/${bootGhcjs.name}"
# #       wrapProgram $out/bin/haddock-ghcjs --add-flags "-B$out/lib/${bootGhcjs.name}"
# #       wrapProgram $out/bin/ghcjs-pkg --add-flags "--global-package-db=$out/lib/${bootGhcjs.name}/package.conf.d"

# #       env PATH=$out/bin:$PATH $out/bin/ghcjs-boot -j1 --with-ghcjs-bin $out/bin
# #     '';

#     # We hard code -j1 as a temporary workaround for
#     # https://github.com/ghcjs/ghcjs/issues/654
#     # enableParallelBuilding = true;

#     inherit passthru;

#     meta.platforms = passthru.bootPkgs.ghc.meta.platforms;
#     meta.maintainers = [lib.maintainers.elvishjerricco];
#     meta.hydraPlatforms = [];
#   };

# in
# { inherit bootDrv bootGhcjs;
#   configuredSrc = passthru.configuredSrc;
# }
