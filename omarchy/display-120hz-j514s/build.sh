#!/bin/bash
# Builds appledrm.ko with appledrm-120hz.patch for the running kernel, out of tree
# against its installed headers. Refuses to build if the source's module parameters
# differ from the packaged module's, which means the commit doesn't match the kernel.
#
# Usage: build.sh [COMMIT] [WORKDIR]
#   COMMIT   omacom/linux-aurora commit the running kernel was built from
#            (default: the one for linux-aurora 7.2.11.aurora14-1)
#   WORKDIR  default ~/.cache/display-120hz-j514s
set -euo pipefail

commit=${1:-4fdd0fc5c931ef9f14474942b37c3d451e97fc04}
work=${2:-$HOME/.cache/display-120hz-j514s}
here=$(cd "$(dirname "$0")" && pwd)
kv=$(uname -r)
headers=/usr/lib/modules/$kv/build
stock=/usr/lib/modules/$kv/kernel/drivers/gpu/drm/apple/appledrm.ko
src=$work/linux-aurora

[[ -d $headers ]] || { echo "no headers for $kv (install linux-aurora-headers)" >&2; exit 1; }

if [[ ! -d $src/.git ]]; then
  git init -q "$src"
  git -C "$src" remote add origin https://github.com/omacom/linux-aurora.git
  git -C "$src" sparse-checkout set --no-cone /drivers/gpu/drm/apple/
fi
git -C "$src" fetch -q --depth 1 --filter=blob:none origin "$commit"
git -C "$src" checkout -q --force FETCH_HEAD

# Same parameter set as the packaged module, or this is the wrong source.
diff <(grep -rhoE 'MODULE_PARM_DESC\(\s*[a-z0-9_]+' "$src/drivers/gpu/drm/apple" | sed 's/.*(\s*//' | sort) \
     <(modinfo -F parm "$stock" | cut -d: -f1 | sort) \
  || { echo "source at $commit does not match the packaged appledrm for $kv" >&2; exit 1; }

rm -rf "$work/build"
cp -r "$src/drivers/gpu/drm/apple" "$work/build"
(cd "$work/build" && sed 's#drivers/gpu/drm/apple/##' "$here/appledrm-120hz.patch" | patch -s -p1)
make -s -C "$headers" M="$work/build" LLVM=1 -j"$(nproc)" modules
llvm-strip --strip-debug -o "$work/appledrm.ko" "$work/build/appledrm.ko"
modinfo -F parm "$work/appledrm.ko" | grep -q '^t6030_early_flip:'
echo "Built $work/appledrm.ko for $kv"
