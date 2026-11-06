# 120 Hz on the M3 Pro display (J514s)

The built-in panel reports 3024x1964@120, but on stock `linux-aurora` it shows
60 fps. The T6030 display driver sends swaps to the 14.7 DCP firmware without
presentation timing words, so the firmware completes at most one swap per
16.7 ms. The driver also blocks each commit for about 2.75 ms until the firmware
acknowledges the swap, which caps Hyprland near 100 fps even with the timing
words.

`appledrm-120hz.patch` carries two upstream changes to `drivers/gpu/drm/apple/`:

- [omacom/linux-aurora#358](https://github.com/omacom/linux-aurora/pull/358):
  sets `swap_timestamps` on the T6030 board record (60 to about 100 fps).
- The opt-in early flip from
  [omacom/linux-aurora#31](https://github.com/omacom/linux-aurora/issues/31),
  as the module parameter `t6030_early_flip`. It sends the flip event before the
  swap reaches the firmware (about 100 to 120 fps). It is off by default, and
  `install.sh` turns it on from boot.

Only `appledrm.ko` is rebuilt, out of tree against the installed kernel headers.
The rest of the kernel stays stock.

## Status

Tested on 2026-11-05 on `linux-aurora 7.2.11.aurora14-1` (DCP firmware 14.7),
Hyprland, with `fps-test.sh`:

| Driver | Display fps at 10 s | Dropped | vsync jitter |
| --- | --- | --- | --- |
| Stock | 59.6 | 0 | 1.02 |
| #358 | 98 to 103 | 0 | 0.33 to 0.39 |
| #358 and early flip | 119.0 to 119.7 | 0 | 0.19 to 0.30 |

There were no DCP errors, flip failures or GPU faults in the kernel log. Results
are posted on #358.

## Install

```sh
./build.sh                    # ~/.cache/display-120hz-j514s, about 5 s
sudo ./install.sh             # module, early-flip config, kernel hold, boot image
# reboot
./fps-test.sh                 # expect about 119
```

`build.sh` defaults to commit `4fdd0fc5`, which matches
`linux-aurora 7.2.11.aurora14-1`. For another kernel, pass the matching commit:
`./build.sh <commit>`. It stops if the source's module parameters differ from the
packaged module's, which means the wrong commit.

`install.sh` adds `IgnorePkg = linux-aurora linux-aurora-headers` to
`/etc/pacman.conf`. A new kernel would boot its stock driver at 60 fps, so the
hold keeps 120 Hz but also skips kernel fixes until it is removed.

To turn early flip off without a reboot, for example if an app flickers:

```sh
echo N | sudo tee /sys/module/appledrm/parameters/t6030_early_flip
```

## Removing

When a `linux-aurora` release includes #358 (and early flip), run
`sudo ./uninstall.sh`, then `omarchy update` and reboot. It removes the module,
the early-flip config and the kernel hold.

If the display doesn't come up after `install.sh`, press `e` on the boot menu
entry, add `module_blacklist=appledrm` to the kernel line, boot on the
framebuffer, and run `sudo ./uninstall.sh`.
