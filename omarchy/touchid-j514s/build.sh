#!/bin/bash
# Builds the patched apple-sep.ko and t6030-j514s.dtb with Omarchy's own
# linux-aurora recipe, so the module matches the installed kernel exactly.
#
# Usage: build.sh [WORKDIR]   (default ~/.cache/touchid-j514s)
#
# Only vmlinux, the DTB and the one module are built, with 6 jobs: a full -j11
# package build crashed this Mac (no CPU thermal zones, so no throttling).
# Needs: clang18 llvm18 lld18 clang llvm lld dtc pahole rustup python git, and
# the omarchy-pkgs recipe whose pkgver matches `pacman -Q linux-aurora`.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
work=${1:-$HOME/.cache/touchid-j514s}
recipe=$work/linux-aurora
mkdir -p "$work"

if [[ ! -f $recipe/PKGBUILD ]]; then
  git clone -q --depth 1 --filter=blob:none --sparse https://github.com/omacom/omarchy-pkgs.git "$work/omarchy-pkgs"
  git -C "$work/omarchy-pkgs" sparse-checkout set pkgbuilds/linux-aurora
  cp -r "$work/omarchy-pkgs/pkgbuilds/linux-aurora" "$recipe"
fi
cd "$recipe"

# shellcheck disable=SC1091 # the recipe's own variables
source <(grep -E '^(_commit|_auroraver|_aurorarel|pkgrel)=' PKGBUILD)
want="$_auroraver.aurora$_aurorarel-$pkgrel"
have=$(pacman -Q linux-aurora | awk '{print $2}')
[[ $want == "$have" ]] || { echo "recipe is linux-aurora $want but $have is installed" >&2; exit 1; }

# A resumable source tarball instead of the recipe's full git clone, which
# crawled at ~1 MB/s; and the J514s patch added to the recipe's patch list.
cp "$here/linux-aurora-j514s-touchid.patch" j514s-touchid.patch
tarball=linux-$_commit.tar.gz
until gzip -t "$tarball" 2>/dev/null; do
  curl -sSL -C - --retry 5 -o "$tarball" "https://codeload.github.com/omacom/linux-aurora/tar.gz/$_commit"
done
if ! grep -q j514s-touchid.patch PKGBUILD; then
  sed -i "s|\"linux::git+https://github.com/omacom/linux-aurora.git#commit=\${_commit}\"|\"linux-\${_commit}.tar.gz\"|; \
s|^_srcname=linux\$|_srcname=linux-aurora-\${_commit}|; \
s|rust-toolchain.toml bindgen-kernel.py config)|rust-toolchain.toml bindgen-kernel.py config j514s-touchid.patch)|" PKGBUILD
  python3 - <<'EOF'
s = open('PKGBUILD').read()
# One more checksum for the patch, before sha256sums' closing parenthesis.
end = s.index(')', s.index('sha256sums=('))
open('PKGBUILD', 'w').write(s[:end] + "\n            'SKIP'" + s[end:])
EOF
fi

# Extract, patch and configure only (prepare() also builds the pinned bindgen).
makepkg -o -C -f

src=$recipe/src/linux-aurora-$_commit
out=$src/build/base
cd "$src"
export ARCH=arm64 KBUILD_BUILD_HOST=archlinux KBUILD_BUILD_USER=linux-aurora RUSTUP_TOOLCHAIN=1.85.0
export AURORA_BINDGEN_REAL=$recipe/src/private-bindgen/rust-bindgen-0.73.2/target/release/bindgen
RUSTFMT=$(rustup which --toolchain 1.99.0 rustfmt)
export RUSTFMT LIBCLANG_PATH=/usr/lib/llvm18/lib
m() { make LLVM=/usr/lib/llvm18/bin/ BINDGEN="$recipe/src/bindgen-kernel.py" LOCALVERSION= O="$out" -j6 "$@"; }
m vmlinux apple/t6030-j514s.dtb
# The module's macsmc and ecdh_generic imports live in modules this build
# skips; CONFIG_MODVERSIONS is off, so names alone resolve them at load.
m KBUILD_MODPOST_WARN=1 drivers/soc/apple/apple-sep.ko

echo "Built:"
ls -l "$out/drivers/soc/apple/apple-sep.ko" "$out/arch/arm64/boot/dts/apple/t6030-j514s.dtb"
