#!/bin/bash
# create-log.sh — create a new log entry and rebuild MkDocs .pages navigation

DATE=$(date +%Y-%m-%d)
YEAR=$(date +%Y)
MONTH=$(date +%m)
MONTH_NAME=$(date +%B)

FOLDER="docs/logs/$YEAR/$MONTH"
FILE="$FOLDER/$DATE.md"

# Ensure year/month folders exist
mkdir -p "$FOLDER"

# Create new log file with structured template if it doesn't exist
if [ ! -f "$FILE" ]; then
  cat <<EOF > "$FILE"
# Log for $DATE
# Log for $DATE

## Tasks
- 

## Issues
- 

## Solutions
- 

## Next Steps
- 

## Notes
- 
EOF
  echo "Created new log with template: $FILE"
else
  echo "Log already exists: $FILE"
fi

# --- Rebuild month .pages ---
MONTH_PAGES="$FOLDER/.pages"
echo "title: $MONTH_NAME $YEAR" > "$MONTH_PAGES"
echo "nav:" >> "$MONTH_PAGES"
for entry in $(ls "$FOLDER"/*.md | sort); do
  fname=$(basename "$entry")
  echo "  - $fname" >> "$MONTH_PAGES"
done

# --- Rebuild year .pages ---
YEAR_PAGES="docs/logs/$YEAR/.pages"
echo "title: $YEAR" > "$YEAR_PAGES"
echo "nav:" >> "$YEAR_PAGES"
for mdir in $(ls -d docs/logs/$YEAR/*/ | sort); do
  mname=$(basename "$mdir")
  echo "  - $mname/" >> "$YEAR_PAGES"
done

# --- Rebuild root .pages ---
ROOT_PAGES="docs/logs/.pages"
echo "title: Logs" > "$ROOT_PAGES"
echo "nav:" >> "$ROOT_PAGES"
for ydir in $(ls -d docs/logs/*/ | sort); do
  yname=$(basename "$ydir")
  echo "  - $yname/" >> "$ROOT_PAGES"
done

