#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(dirname "$SCRIPT_DIR")
EVE_DATA_DIR="$ROOT/eveData"
SYSTEMS_CSV="$EVE_DATA_DIR/mapSolarSystems.csv"
JUMPS_CSV="$EVE_DATA_DIR/mapSolarSystemJumps.csv"
SDE_WORK_DIR=$(mktemp -d)
SDE_OUTPUT_DIR="$SDE_WORK_DIR/output"

cleanup() {
  rm -rf "$SDE_WORK_DIR"
  rm -f "$SYSTEMS_CSV" "$JUMPS_CSV"
}

trap cleanup 0 1 2 15

cd "$ROOT"

echo 'Installing dependencies'
npm install

echo 'Generating graph from the latest EVE SDE'
mkdir -p "$EVE_DATA_DIR"
sdeconvert --download --format csv --output "$SDE_OUTPUT_DIR"
cp "$SDE_OUTPUT_DIR/mapSolarSystems.csv" "$SYSTEMS_CSV"
cp "$SDE_OUTPUT_DIR/mapSolarSystemJumps.csv" "$JUMPS_CSV"
npm run generateGraph

cleanup
trap - 0 1 2 15

exec sh "$SCRIPT_DIR/run.sh"
