{ lib, ... }:
{
  home.activation.finderSidebar = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    MYSIDES=""
    for candidate in /usr/local/bin/mysides /opt/homebrew/bin/mysides; do
      if [ -x "$candidate" ]; then
        MYSIDES="$candidate"
        break
      fi
    done

    if [ -n "$MYSIDES" ]; then
      set +e
      "$MYSIDES" list 2>/dev/null | /usr/bin/awk -F'\t' '{print $1}' | while IFS= read -r name; do
        [ -n "$name" ] && "$MYSIDES" remove "$name" >/dev/null 2>&1
      done

      for entry in \
        "ryanstoffel file://$HOME/" \
        "Developer file://$HOME/Developer/" \
        "Documents file://$HOME/Documents/" \
        "Downloads file://$HOME/Downloads/" \
        "Applications file:///Applications/" \
        "Pictures file://$HOME/Pictures/"; do
        name="''${entry%% *}"
        url="''${entry#* }"
        "$MYSIDES" add "$name" "$url" >/dev/null 2>&1
      done
      set -e
    fi
  '';
}
