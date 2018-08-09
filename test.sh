#!/bin/bash

set -euo pipefail

DC="${DC:-dmd}"
dub test --build=unittest-cov
dub run -c unittest-unthreaded --build=unittest-cov --compiler="$DC"
dub run -c unittest-light --build=unittest
