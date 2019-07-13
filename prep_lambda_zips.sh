#!/bin/bash
CONN_FILE="conn-obj-func.zip"
DISCONN_FILE="disconn-obj-func.zip"
ACT_FILE="act-obj-func.zip"

CONN_PATH="src/connect"
DISCONN_PATH="src/disconnect"
ACT_PATH="src/action"
set -e

cd "`dirname $0`"
echo "Creating $CONN_FILE" && zip -j "$CONN_FILE" "$CONN_PATH/"*
echo "Creating $DISCONN_FILE" && zip -j "$DISCONN_FILE" "$DISCONN_PATH/"*
echo "Creating $ACT_FILE" && zip -j "$ACT_FILE" "$ACT_PATH/"*