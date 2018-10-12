{ stdenv, cacert, git, rust, cargo-vendor, python3 }:
let cargo-vendor-normalise = stdenv.mkDerivation {
  name = "cargo-vendor-normalise";
  src = ./cargo-vendor-normalise.py;
  nativeBuildInputs = [ python3.pkgs.wrapPython ];
  unpackPhase = ":";
  installPhase = "install -D $src $out/bin/cargo-vendor-normalise";
  pythonPath = [ python3.pkgs.toml ];
  postFixup = "wrapPythonPrograms";
  doInstallCheck = true;
  installCheckPhase = ''
    # check that ./fetchcargo-default-config.toml is a fix point
    reference=${./fetchcargo-default-config.toml}
    < $reference $out/bin/cargo-vendor-normalise > test;
    cmp test $reference
  '';
  preferLocalBuild = true;
};
in
{ name ? "cargo-deps", src, srcs, patches, sourceRoot, sha256, cargoUpdateHook ? ""
, flagNoMergeSources ? false }:
stdenv.mkDerivation {
  name = "${name}-vendor";
  nativeBuildInputs = [ cacert cargo-vendor git cargo-vendor-normalise rust.cargo ];
  inherit src srcs patches sourceRoot;

  phases = "unpackPhase patchPhase installPhase";

  installPhase = ''
    if [[ ! -f Cargo.lock ]]; then
        echo
        echo "ERROR: The Cargo.lock file doesn't exist"
        echo
        echo "Cargo.lock is needed to make sure that cargoSha256 doesn't change"
        echo "when the registry is updated."
        echo

        exit 1
    fi

    export CARGO_HOME=$(mktemp -d cargo-home.XXX)

    ${cargoUpdateHook}

    mkdir -p $out
    ${if flagNoMergeSources
      then ''
        cargo vendor --no-merge-sources $out > config
        substituteInPlace config --replace "$out" "@vendor@"
      ''
      else "cargo vendor $out | cargo-vendor-normalise > config"}
    # fetchcargo used to never keep the config output by cargo vendor
    # and instead hardcode the config in ./fetchcargo-default-config.toml.
    # This broke on packages needing git dependencies, so now we keep the config.
    # But not to break old cargoSha256, if the previous behavior was enough,
    # we don't store the config.
    if ! cmp config ${./fetchcargo-default-config.toml} > /dev/null; then
      install -Dt $out/.cargo config;
    fi;
  '';

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = sha256;

  impureEnvVars = stdenv.lib.fetchers.proxyImpureEnvVars;
  preferLocalBuild = true;
}
