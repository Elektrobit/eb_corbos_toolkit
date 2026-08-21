#!/bin/sh
# Copyright 2026 Elektrobit. All rights reserved.

# Detect actual terminal size via ANSI escape sequences and update stty.
# Fixes line-wrapping issues on serial consoles (e.g. QEMU -nographic)
# where the guest defaults to 80x24 but the host terminal is larger.

# Only run on interactive terminals
[ -t 0 ] || return 0 2>/dev/null || exit 0

echo "Trying to determine host terminal size..."
# Save and set raw mode so we can read the terminal response
# min 0 time 5 = return from read() after 0.5s of no data.
saved=$(stty -g)
stty raw -echo min 0 time 5

rows=""
cols=""
attempt=0
while [ "$attempt" -lt 5 ]; do
    attempt=$((attempt + 1))

    # Drain any stale bytes in the input buffer
    dd bs=256 count=1 < /dev/tty > /dev/null 2>&1

    # Save cursor, move to bottom-right corner, query position, restore cursor
    printf '\0337\033[9999;9999H\033[6n\0338' > /dev/tty

    # Read response (up to 32 bytes, --foreground keeps dd in the
    # foreground process group so it can read from the tty)
    response=$(timeout --foreground 5 dd bs=1 count=32 2>/dev/null < /dev/tty)

    # Validate response matches ESC[rows;colsR
    rows=$(printf '%s' "$response" | sed -n 's/.*\[\([0-9]*\);\([0-9]*\)R.*/\1/p')
    cols=$(printf '%s' "$response" | sed -n 's/.*\[\([0-9]*\);\([0-9]*\)R.*/\2/p')

    if [ -n "$rows" ] && [ -n "$cols" ]; then
        break
    fi

    # Invalid or no response — wait before retrying
    sleep 1
done

# Drain any remaining bytes to prevent stray escape sequences from
# appearing on the console after terminal settings are restored.
dd bs=256 count=1 < /dev/tty > /dev/null 2>&1

# Restore terminal settings
stty "$saved"

# Apply detected size
if [ -n "$rows" ] && [ -n "$cols" ]; then
    echo "Setting terminal size to rows=$rows, cols=$cols"
    stty rows "$rows" cols "$cols"
fi
