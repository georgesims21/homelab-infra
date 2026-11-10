#!/usr/bin/env bash
# Take a "before" snapshot of this node ahead of installing Kubernetes.
#
# chmod +x k8s-baseline.sh
# ./k8s-baseline.sh          # as your normal user, not "sudo bash ..."
# script -a ~/k8s-setup.log  # then start recording; `exit` stops it
#
# Post install diff:
#
# cd ~/k8s-before
# comm -13 modules       <(lsmod | awk 'NR>1 {print $1}' | sort)           # new kernel modules
# comm -13 enabled-units <(systemctl list-unit-files --state=enabled | sort)
# diff packages          <(apt-mark showmanual | sort)
# diff sysctl            <(sudo sysctl -a 2>/dev/null | sort)
# diff iptables          <(sudo iptables-save)                              # kube-proxy and CNI rules
# sudo find / -xdev -cnewer /root/k8s-marker 2>/dev/null                    # every file touched since time zero
# set -eu

BASE="$HOME/k8s-before"
MARKER=/root/k8s-marker

# /root is mode 700, so a plain `[ -e ]` as a normal user would always say "no".
if sudo test -e "$MARKER"; then
  echo "$MARKER already exists: a baseline was taken already. Refusing to overwrite." >&2
  echo "If you really want a fresh one: sudo rm $MARKER" >&2
  exit 1
fi

mkdir -p "$BASE"

# "Time zero" for later: sudo find / -xdev -cnewer /root/k8s-marker
sudo touch "$MARKER"

# Packages
apt-mark showmanual | sort > "$BASE/packages"            # installed on purpose
dpkg-query -W | sort > "$BASE/packages-all"              # full footprint incl. dependencies

# Kernel and boot-time state
sudo sysctl -a 2>/dev/null | sort > "$BASE/sysctl"
lsmod | awk 'NR>1 {print $1}' | sort > "$BASE/modules"  # NR>1 skips the header line
systemctl list-unit-files --state=enabled | sort > "$BASE/enabled-units"

# Extras: things kubelet, kube-proxy and the CNI will change or care about
sudo iptables-save > "$BASE/iptables" 2>/dev/null || true
sudo nft list ruleset > "$BASE/nft" 2>/dev/null || true
ip -br addr > "$BASE/ip-addr"
ip route > "$BASE/ip-route"
sudo ss -tulpn | sort > "$BASE/listening"
swapon --show > "$BASE/swap" || true                     # kubelet refuses to run with swap by default
stat -fc %T /sys/fs/cgroup > "$BASE/cgroup"              # cgroup2fs = cgroup v2

echo "Baseline saved to $BASE (marker: $MARKER)."
echo "To record the install session, run this in your terminal:"
echo "  script -a ~/k8s-setup.log    # type 'exit' to stop"