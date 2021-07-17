{ fetchpatch, haskellLib }:

let inherit (haskellLib) doJailbreak dontHaddock dontCheck;
    patch = fetchpatch
      { url = "https://github.com/simonmar/happy/commit/66982277ac7aed23edbb36c5f7aa5a86e5bdf778.patch";
        sha256 = "sha256-ItGKcRgzNBSOjcfmgFMo9Pan4rdPU4THduLh+BSi0PA=";
        name = "happy-1.19.11.patch";
      };
in self: super: {
  # Use specific version of happy.
  # https://gitlab.haskell.org/ghc/ghc/-/issues/19603
  happy = self.happy_1_19_11.overrideAttrs (_: {
    patches = ./happy.patch;
  });
  # ghcjs =
  #   # https://github.com/simonmar/happy/pull/142
  #   let happy = self.happy_1_19_11.overrideAttrs (oldAttrs:
  #         { patches = ./happy.patch;
  #         });
  #   in
  #     super.ghcjs.override {
  #       inherit happy;
  #     };
}
