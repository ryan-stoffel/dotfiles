{ lib, stdenvNoCC, fetchurl, undmg }:

stdenvNoCC.mkDerivation {
  pname = "bluebubbles-server";
  version = "1.9.9";

  src = fetchurl {
    url = "https://github.com/BlueBubblesApp/bluebubbles-server/releases/download/v1.9.9/BlueBubbles-1.9.9-arm64.dmg";
    hash = "sha256-+v1lDIg/UudJSmYl5FJJ8hRNGXN4pNVxQ8z2GYuy6GI=";
  };

  nativeBuildInputs = [ undmg ];
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Applications"
    cp -R BlueBubbles.app "$out/Applications/"
    runHook postInstall
  '';

  meta = {
    description = "macOS server for forwarding iMessages";
    homepage = "https://bluebubbles.app/";
    license = lib.licenses.asl20;
    platforms = [ "aarch64-darwin" ];
  };
}
