-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- SDDM autologs in after the disk unlock, so lock right away: boot and reboot
-- land on the same lock screen as idle and suspend. Retries until the shell's
-- lock plugin answers, giving up after 30s.
o.exec_on_start([[timeout 30 bash -c 'until [ "$(omarchy-shell lock lock 2>/dev/null)" = ok ]; do sleep 0.2; done']])
