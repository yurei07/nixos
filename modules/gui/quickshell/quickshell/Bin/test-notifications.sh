#!/usr/bin/env -S bash

echo "Sending 8 test notifications..."

# Send 8 notifications with numbers
for i in {1..8}; do
    notify-send "Notification $i" "This is test notification number $i of 8"
    sleep 1
done

echo "All notifications sent!"

# Additional tests for icon/image handling
if command -v notify-send >/dev/null 2>&1; then
    echo "Sending icon/image tests..."

    # 1) Themed icon name
    notify-send -i dialog-information "Icon name test" "Should resolve from theme (dialog-information)"

    # 2) Absolute path if a sample image exists
    SAMPLE_IMG="/usr/share/pixmaps/debian-logo.png"
    if [ -f "$SAMPLE_IMG" ]; then
        notify-send -i "$SAMPLE_IMG" "Absolute path test" "Should show the provided image path"
    fi

    # 3) file:// URL form
    if [ -f "$SAMPLE_IMG" ]; then
        notify-send -i "file://$SAMPLE_IMG" "file:// URL test" "Should display after stripping scheme"
    fi

    echo "Icon/image tests sent!"
fi
