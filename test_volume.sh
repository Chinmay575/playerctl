#!/bin/bash
# Test script to verify volume sync is working
# This will show the current volume from playerctl

echo "Testing playerctl volume command..."
echo "Current volume:"
playerctl volume

echo ""
echo "Setting volume to 0.5 (50%)..."
playerctl volume 0.5
sleep 1
echo "Current volume after setting to 50%:"
playerctl volume

echo ""
echo "Setting volume to 0.8 (80%)..."
playerctl volume 0.8
sleep 1
echo "Current volume after setting to 80%:"
playerctl volume

echo ""
echo "If you see volume values above, playerctl is working correctly."
echo "The app should sync these changes within 2 seconds."
