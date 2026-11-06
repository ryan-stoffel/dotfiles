# Touch ID on the M3 Pro (J514s)

Touch ID on Omarchy works only on Macs whose Secure Enclave (SEP) the
`linux-aurora` driver has a profile for. The M3 Pro had none, so its device tree
left out the SEP and the sensor, and Omarchy's setup refused the board.

The J514s wiring, read from Apple's device tree (`adt-dump.py`), matches the M3 Air
(J613), where Touch ID already works: the same SEP, DART and mailbox addresses, the
same `R3` sensor and SPI settings. Only the interrupts, the sensor's SPI bus
(`0x289108000`) and its power pin (NUB GPIO 33) differ.
`linux-aurora-j514s-touchid.patch` adds those nodes to `t6030.dtsi` and
`t6030-j514s.dts`, and a `T6030/J514s` profile to `drivers/soc/apple/profile.rs`
that reuses the M3 Air profile with the SPI address changed.

## Status

Tested on 2026-11-05 on `linux-aurora 7.2.11.aurora14-1` (system firmware 27.0):

| Check | Result |
| --- | --- |
| Boot with patched DTB | m1n1 reserves `sep-firmware` and passes the manifests |
| Read-only attach | 7 endpoints in 18 messages, 12 known, `hwrng` registered, `/dev/sep-bio` |
| xART store read | 170 slots, 12 live records, 0 malformed |
| Keybag with `xart_guard=1` | provisioned, 0 refusals |
| Sensor | `online`, `attached` |
| Enrol and verify | 4 steps, `Matched` |
| `sudo` by fingerprint | prompts for the finger |

Not tested yet: a match after a reboot, polkit, the lock screen, suspend and
resume, and macOS Touch ID and Keychain afterwards.

## Install

A kernel update replaces the patched DTB and module, which turns Touch ID off until
this is built and installed for the new kernel. Your enrolment stays in
`/var/lib/aurora-sep-*`. Update and reboot first, so that the recipe and the running
kernel are the same version.

```sh
./build.sh                    # ~/.cache/touchid-j514s; vmlinux, DTB and module, 6 jobs
sudo ./install.sh             # DTB, module, calibration, update-m1n1 (keeps boot.bin.old)
# reboot
sudo ./test-readonly.sh       # first time only: attach with SEP writes off
sudo ./enable-writes.sh       # first time only: Omarchy's agreement, xart_guard=1
# reboot
omarchy-setup-security-fingerprint
```

`build.sh` needs `clang18 llvm18 lld18 clang llvm lld dtc pahole rustup`. It
stops if the patch doesn't apply to the new kernel. A full `-j11` package build
crashed this Mac. The kernel has no CPU thermal zones, so nothing throttles the
CPU when it overheats. Keep the build small and the Mac plugged in.

`sudo ./uninstall.sh` restores the stock DTB and driver for the running kernel.
Remove enrolled fingers first with `omarchy-remove-security-fingerprint`. If Linux
won't boot after `install.sh`, start macOS, run `diskutil mount disk0s4`, and
copy `m1n1/boot.bin.old` over `m1n1/boot.bin`.

## Risk

Enrolling makes Linux write the SEP's xART anti-replay store, which macOS shares.
`xart_guard=1` refuses any change to records this Linux install did not create.
If a write goes wrong anyway, macOS Touch ID or Keychain can break, and the fix
can be a DFU restore from a second Mac.
