#!/usr/bin/env bash
set -euo pipefail

toolchain_version="23.1.0"
toolchain_root="${TOOLCHAIN_ROOT:-${PWD}/.toolchain}"
archive="${TMPDIR:-/tmp}/ATfE-${toolchain_version}-Linux-x86_64.tar.xz"
url="https://github.com/arm/arm-toolchain/releases/download/release-${toolchain_version}-ATfE/ATfE-${toolchain_version}-Linux-x86_64.tar.xz"
expected_sha256="a7be511613af15151c93961ad39c8cf9ae6889a453c8b547f42f4051a416dc8e"

if [[ ! -x "${toolchain_root}/bin/clang++" ]]; then
  mkdir -p "${toolchain_root}"
  if [[ ! -f "${archive}" ]]; then
    curl --fail --location --retry 3 --output "${archive}" "${url}"
  fi

  actual_sha256="$(sha256sum "${archive}" | cut -d ' ' -f 1)"
  if [[ "${actual_sha256}" != "${expected_sha256}" ]]; then
    printf 'SHA-256 mismatch for %s\nexpected: %s\nactual:   %s\n' \
      "${archive}" "${expected_sha256}" "${actual_sha256}" >&2
    exit 1
  fi

  tar --extract --xz --file "${archive}" --strip-components=1 --directory "${toolchain_root}"
fi

compiler="${toolchain_root}/bin/clang++"
reproducer="$(mktemp --suffix=.cpp)"
sanity="$(mktemp --suffix=.cpp)"
failure_log="$(mktemp)"
trap 'rm -f "${reproducer}" "${sanity}" "${failure_log}"' EXIT

cat > "${reproducer}" <<'EOF'
#include <cmath>

int iszero();

int main() {
  return 0;
}
EOF

cat > "${sanity}" <<'EOF'
#include <cmath>

int classify(float value) {
  return std::fpclassify(value);
}
EOF

if "${compiler}" --target=arm-none-eabi -fsyntax-only "${reproducer}" >"${failure_log}" 2>&1; then
  printf 'Expected the iszero reproducer to fail, but it compiled.\n' >&2
  exit 1
fi

if ! grep -q 'iszero' "${failure_log}" || ! grep -q 'expected' "${failure_log}"; then
  printf 'The compiler failed, but not for the expected iszero macro collision:\n' >&2
  cat "${failure_log}" >&2
  exit 1
fi

cat "${failure_log}"
"${compiler}" --target=arm-none-eabi -fsyntax-only "${sanity}"
printf 'Reproduction passed: iszero remains an active macro and fpclassify compiles.\n'
