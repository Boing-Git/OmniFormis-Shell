#!/usr/bin/env bash

hyprctl reload; 

pkill -9 quickshell
pkill -9 .quickshell-wra

sleep 0.5
quickshell &
disown