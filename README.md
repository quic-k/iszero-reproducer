# libc++ picolibc `iszero` reproducer

This repository reproduces a libc++ and picolibc header interaction where
`<cmath>` leaves picolibc's `iszero` macro defined in C++ mode.

The macro rewrites unrelated user identifiers:

```cpp
#include <cmath>

int iszero();
```

The Arm Toolchain for Embedded (ATfE) uses picolibc by default. The expected
result is that the declaration above fails with an error referring to:

```text
#define iszero(__x) (fpclassify(__x) == FP_ZERO)
```

The same toolchain must still compile the standard `fpclassify` calls. This
keeps the reproduction focused on the leaked macro rather than a general
`<cmath>` failure.

## Run locally

The script downloads and verifies the public Arm toolchain release, extracts
it into `.toolchain/`, and runs both checks:

```bash
./run.sh
```

The script exits successfully when the `iszero` test fails for the expected
macro-expansion diagnostic and the `fpclassify` test succeeds.

## CI

GitHub Actions runs the same script on Ubuntu. The toolchain archive is not
stored in this repository; it is downloaded from the Arm Toolchain release and
verified using its published SHA-256 digest.

## Upstream context

libc++ already removes the traditional C math classification macros from its
C++ `<math.h>` wrapper. The picolibc `iszero` macro remains defined, unlike the
other macros checked by this reproducer. Relevant upstream locations are:

- `libcxx/include/math.h`
- `libcxx/include/__cxx03/math.h`
