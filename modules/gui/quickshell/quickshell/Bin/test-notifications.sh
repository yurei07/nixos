#!/usr/bin/env -S bash

echo "Sending 8 test notifications..."

# Send 8 notifications with numbers
for i in {1..8}; do
    notify-send "Notification $i" "This is test notification number $i of 8"
    sleep 1
done

echo "All notifications sent!"
