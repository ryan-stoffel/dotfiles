#!/bin/bash
# After install.sh and a reboot: loads apple-sep read-only and reports whether
# the Secure Enclave attached. Run as root. Writes nothing to the enclave.
grep -qs 'xart_writes=0 provision_keybag=0' /etc/modprobe.d/aurora-sep.conf ||
  { echo "the read-only option file is missing; refusing" >&2; exit 1; }
echo "sep alias: $(tr -d '\0' </proc/device-tree/aliases/sep 2>/dev/null)"
ls /proc/device-tree/soc/sep@29e400000/ | grep -E 'memory-region$|manifest' | tr '\n' ' '; echo
modprobe macsmc; modprobe ecdh_generic # unlisted dependencies, see build.sh
timeout 60 modprobe apple-sep; echo "modprobe exit=$?"
sleep 5
journalctl -k -b --no-pager | grep -E 'apple_sep' | grep -v discover | tail -15
ls -l /dev/sep-bio
grep -H . /sys/bus/platform/drivers/apple_sep/*.sep/diag/{profile,attach,endpoints,xart,sensor} 2>/dev/null
