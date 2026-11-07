{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libGL,
  libkrb5,
  libnotify,
  libpulseaudio,
  libva,
  libxkbcommon,
  nspr,
  nss,
  pango,
  pipewire,
  systemd,
  vulkan-loader,
  wayland,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxcb,
  commandLineArgs ? "",
}:

let
  sources = {
    x86_64-linux = {
      arch = "x86_64";
      hash = "sha256-bNfyQBU8ucDN+ie/GmZR3crnOomK/ESak90Q2oO0vUU=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-Zyo+nVge36QUSS6hJlKqvfAucAuOieK1WZQZxw0B3EQ=";
    };
  };
  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "no support ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "helium";
  version = "0.21.1.1";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${finalAttrs.version}/helium-${finalAttrs.version}-${source.arch}_linux.tar.xz";
    inherit (source) hash;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libkrb5
    libxkbcommon
    nspr
    nss
    pango
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
  ];
runtimeDependencies = map lib.getLib [
    libGL
    libva
    libnotify
    libpulseaudio
    pipewire
    systemd
    vulkan-loader
    wayland
  ];

  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/helium $out/bin
    cp -r . $out/opt/helium
    rm -f $out/opt/helium/apparmor.cfg

    makeWrapper $out/opt/helium/helium $out/bin/helium \
      "''${gappsWrapperArgs[@]}" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
      --add-flags ${lib.escapeShellArg commandLineArgs}

    install -Dm644 helium.desktop $out/share/applications/helium.desktop
    install -Dm644 product_logo_256.png $out/share/icons/hicolor/256x256/apps/helium.png
    substituteInPlace $out/share/applications/helium.desktop \
      --replace-quiet "Exec=helium" "Exec=$out/bin/helium" \
      --replace-quiet "Icon=helium" "Icon=helium"

    runHook postInstall
  '';

  meta = {
    description = "Chromium-based browser focused on privacy";
    homepage = "https://github.com/imputnet/helium";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "helium";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
