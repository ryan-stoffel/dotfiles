{ config, lib, ... }:
let
  icon = "${config.home.homeDirectory}/.dotfiles/nix-darwin/assets/vesktop.icns";
  cask = "/Applications/Vesktop.app";
  app = "/Applications/Discord.app";
in
{
  # Vesktop is the Discord client here, so it lives under the Discord name and
  # mark. Both changes are external to the bundle's Contents/, leaving the
  # notarized seal intact: the name is just the bundle filename, and the icon is
  # a top-level `Icon\r` Finder custom icon.
  #
  # The cask installs to Vesktop.app, so a reinstall resurrects that path; the
  # rename below reapplies on every rebuild, and a freshly installed bundle
  # replaces the renamed one.
  home.activation.vesktopApp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d "${cask}" ]; then
      run rm -rf "${app}"
      run mv "${cask}" "${app}"
    fi

    if [ -d "${app}" ] && [ -f "${icon}" ]; then
      run /usr/bin/osascript -l JavaScript \
        -e 'ObjC.import("AppKit")' \
        -e 'const img = $.NSImage.alloc.initWithContentsOfFile("${icon}")' \
        -e 'if (!img.js) throw new Error("icon failed to load")' \
        -e '$.NSWorkspace.sharedWorkspace.setIconForFileOptions(img, "${app}", 0)' \
        > /dev/null
      run /usr/bin/touch "${app}" || true
    fi
  '';
}
