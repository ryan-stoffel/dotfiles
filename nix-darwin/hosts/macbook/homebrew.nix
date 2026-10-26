# MacBook apps, in addition to modules/darwin/homebrew.nix.
{ ... }:
{
  # Keep taps used by manually installed tools during cleanup.
  homebrew.taps = [
    { name = "clerk/stable"; trusted = false; }
    { name = "depot/tap"; trusted = false; }
  ];

  homebrew.casks = [
    "microsoft-word"
    "microsoft-excel"
    "microsoft-powerpoint"
    "microsoft-teams"
  ];
}
