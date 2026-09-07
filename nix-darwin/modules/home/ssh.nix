{ config, ... }:
{
  # Public connection settings only. Private keys stay outside the repository.
  home.file.".ssh/config".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.dotfiles/ssh/config";
}
