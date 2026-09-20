#!/bin/bash
# Start RPI camera stream on port 8080
echo "Starting RPI camera stream on port 8080..."

rpicam-vid -t 0 --inline --listen -o tcp://0.0.0.0:8080 --width 640 --height 480 --framerate 15
