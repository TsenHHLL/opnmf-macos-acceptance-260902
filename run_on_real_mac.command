#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
archive="$script_dir/GUI-260902.zip"
expected_sha="24BC909FA1D7946B21E2FE644C674B1B072CD22DAAAF16A9A3600B96B9CA1CE0"

if [[ "$(uname -m)" != "arm64" ]]; then
  echo "ERROR: This acceptance run must use an Apple Silicon Mac (arm64)." >&2
  exit 2
fi

if [[ ! -f "$archive" ]]; then
  echo "ERROR: Missing $archive" >&2
  exit 3
fi

if ! command -v matlab >/dev/null 2>&1; then
  echo "ERROR: MATLAB is not on PATH. Run this from a Terminal where native Apple Silicon MATLAB R2024b is available." >&2
  exit 4
fi

if ! /usr/libexec/java_home -v 11 >/dev/null 2>&1; then
  echo "ERROR: Java 11 is required. Install Amazon Corretto 11, then rerun." >&2
  exit 5
fi
export JAVA_HOME="$(/usr/libexec/java_home -v 11)"

echo "$expected_sha  $archive" | shasum -a 256 -c -

timestamp="$(date +%Y%m%d_%H%M%S)"
run_dir="$script_dir/real_mac_run_$timestamp"
artifact_dir="$run_dir/artifacts/real-arm64"
mkdir -p "$artifact_dir"
ditto -x -k "$archive" "$run_dir"
cp "$script_dir/mac_acceptance_probe.m" "$run_dir/mac_acceptance_probe.m"

{
  sw_vers
  uname -a
  sysctl -n hw.memsize | awk '{printf "MemoryBytes: %s\n", $1}'
} | tee "$artifact_dir/macos.txt"

cd "$run_dir"
matlab -batch 'mac_acceptance_probe("real-arm64")'

echo "Acceptance evidence: $artifact_dir"
