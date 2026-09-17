{ lib, ... }:
{
  # macOS defaults to a 256 soft maxfiles limit for GUI apps. Docker Desktop
  # exhausts it quickly ("too many open files" in com.docker.backend.log).
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "Setting system maxfiles soft limit..."
    /bin/launchctl limit maxfiles 65536 524288 || true
  '';
}
