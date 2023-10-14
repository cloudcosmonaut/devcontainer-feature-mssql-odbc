#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Check installation of opentofu
check "binary is" test 1 -eq "$(find /usr/bin/ -name tofu| wc -l)"

# Report result
reportResults
