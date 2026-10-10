# Mac mini: always-on desktop with the Microsoft apps.
{ ... }:
{
  imports = [ ./homebrew.nix ];

  home-manager.users.ryan-stoffel = { lib, ... }: {
    home.sessionPath = [ "$HOME/.cargo/bin" ];
    programs.zsh.initContent = ''
      [ ! -f "$HOME/.cargo/env" ] || source "$HOME/.cargo/env"
    '';
    home.activation.installRust = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -n "''${DRY_RUN_CMD:-}" ]; then
        echo "Would ensure rustup and a default Rust toolchain are installed."
      else
        if [ ! -x "$HOME/.cargo/bin/rustup" ]; then
          installer=$(mktemp)
          /usr/bin/curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$installer"
          run /bin/sh "$installer" -y --no-modify-path
          rm -f "$installer"
        fi
        if ! "$HOME/.cargo/bin/rustup" show active-toolchain >/dev/null 2>&1; then
          run "$HOME/.cargo/bin/rustup" default stable
        fi
      fi
    '';
  };
}
