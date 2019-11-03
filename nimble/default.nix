{ stdenv, fetchFromGitHub, makeWrapper, nim, openssl }:

stdenv.mkDerivation rec {
  pname = "nimble";
  version = "0.11.0";
  outputs = [ "out" "lib" ];

  nativeBuildInputs = [ nim ];

  buildInputs = [ makeWrapper openssl ];

  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "nimble";
    rev = "v" + version;
    sha256 = "1n8qi10173cbwsai2y346zf3r14hk8qib2qfcfnlx9a8hibrh6rv";
  };

  patches = [ ./json.patch ./subdir.patch ./tempdir.patch ./url.patch ];

  enableParallelBuilding = true;

  NIX_LDFLAGS = [ "-lcrypto" ];

  nimFlags = [ "--cpu:${nim.host.cpu}" "--os:${nim.host.os}" "--nilseqs:on" ];

  buildPhase = ''
    runHook preBuild
    local HOME=$TMPDIR
    nim c $nimFlags -o:nimble src/nimble.nim
    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck
    nimble test
    runHook postCheck
  '';

  # Wrap Nimble so it may find Nim and C compilers
  installPhase = ''
    runHook preInstall
    install -D nimble $out/bin/nimble
    mkdir -p $lib
    cp -r src $lib/
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    inherit (nim.meta) homepage license platforms;
    description = "Package manager for the Nim programming language";
    maintainers = with maintainers; [ ehmry ];
  };
}
