#!/bin/bash
set -euo pipefail

# === Setup Logging ===
LOGFILE="/tmp/cred-sync-import.log"
exec > >(tee -a "$LOGFILE") 2>&1
echo
echo "---- Starting import at $(date) ----"

# === Input Handling ===
if [[ $# -ge 1 && -f "$1" ]]; then
    CSV_FILE="$1"
    echo "Using CSV file from argument: $CSV_FILE"
else
    CSV_FILE=$(ls -1 ~/Downloads/*.csv 2>/dev/null | rofi -dmenu -p "Select CSV file to import:")
    echo "Selected CSV file from Rofi: $CSV_FILE"
fi

# === File Validation ===
if [[ -z "$CSV_FILE" || ! -f "$CSV_FILE" ]]; then
    rofi -e "No valid CSV file selected." || echo "No valid CSV file selected."
    echo "❌ Invalid file: '$CSV_FILE'"
    exit 1
fi

# === Process CSV with dynamic header parsing ===
IMPORT_COUNT=0

tail -n +1 "$CSV_FILE" | awk -v OFS=',' '
    BEGIN {
        FS="\",\"";
        found_header=0;
    }

    function unquote(s) {
        gsub(/^"/, "", s);
        gsub(/"$/, "", s);
        return s;
    }

    NR == 1 {
        for (i = 1; i <= NF; i++) {
            header[i] = tolower(unquote($i));
            if (header[i] == "url") col_url = i;
            if (header[i] == "username") col_user = i;
            if (header[i] == "password") col_pass = i;
        }
        if (!col_url || !col_user || !col_pass) {
            print "❌ Required columns missing: url, username, password";
            exit 1;
        }
        next;
    }

    {
        url  = unquote($col_url);
        user = unquote($col_user);
        pass = unquote($col_pass);

        if (url == "" || user == "" || pass == "") {
            print "→ Skipping incomplete line";
            next;
        }

        domain = url;
        sub(/^https?:\/\//, "", domain);
        split(domain, parts, "/");
        domain = parts[1];

        gsub(/["`$]/, "", domain);
        gsub(/["`$]/, "", user);
        gsub(/["`$]/, "", pass);

        entry = "web/" domain "/" user;
        print "→ Importing to", entry;

        cmd = "echo \"" pass "\\nusername: " user "\\nurl: " url "\" | pass insert -m -f \"" entry "\"";
        result = system(cmd);

        if (result == 0) {
            print "✅ Inserted:", entry;
            import_count++;
        } else {
            print "❌ Failed to insert:", entry;
        }
    }

    END {
        print "IMPORT_COUNT=" import_count > "/tmp/cred-sync-count";
    }
'

# === Final Notification ===
source /tmp/cred-sync-count || IMPORT_COUNT=0
notify-send "✅ Imported $IMPORT_COUNT credentials from file."

# === Optional Cleanup (disabled for debug) ===
# shred -u "$CSV_FILE"
echo "Note: CSV file not deleted (debug mode)."
