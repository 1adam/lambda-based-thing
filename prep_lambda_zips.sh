#!/bin/bash
CONN_FILE="conn-obj-func.zip"
DISCONN_FILE="disconn-obj-func.zip"
ACT_FILE="act-obj-func.zip"

CONN_PATH="src/connect"
DISCONN_PATH="src/disconn"
ACT_PATH="src/action"
set -e

cd "`dirname $0`"
zip -j "$CONN_FILE" "$CONN_PATH/*"
zip -j "$DISCONN_FILE" "$DISCONN_PATH/*"
zip -j "$ACT_FILE" "$ACT_PATH/*"