# Apps installed only on the Mac mini, on top of modules/darwin/homebrew.nix.
{ ... }:
{
  homebrew.casks = [
    # microsoft
    "microsoft-word"
    "microsoft-excel"
    "microsoft-powerpoint"
    "microsoft-teams"
  ];

  homebrew.extraConfig = ''
    mas "Windows App", id: 1295203466 unless File.directory?("/Applications/Windows App.app")
  '';
}
