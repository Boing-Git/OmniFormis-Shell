#!/usr/bin/env bash
env QT_SCALE_FACTOR=1.5 quickshell -p "$(dirname "$(readlink -f "$0")")/../LockScreen.qml" > /tmp/quickshell_lock.log 2>&1
