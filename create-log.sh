#!/bin/bash
# create-log.sh

DATE=$(date +%F)
FILE="docs/logs/${DATE}.md"

# Ensure logs folder exists
mkdir -p docs/logs

# Create the log file if it doesn't exist
if [ ! -f "$FILE" ]; then
  cat <<EOF > "$FILE"
# Daily Log – $DATE

## Tasks Completed
- [ ] Brief bullet points of what you worked on
- [ ] Include commands, configs, or code snippets if relevant

## Issues Encountered
- Describe any errors, failures, or unexpected behavior
- Note logs, error messages, or system outputs

## Solutions / Workarounds
- Steps taken to resolve issues
- Fallback strategies or recovery scripts used

## Next Steps
- What you plan to tackle tomorrow
- Dependencies or blockers to keep in mind

## Notes & Reflections
- Insights gained, lessons learned
- Stakeholder communication or documentation updates
EOF
  echo "Created new log: $FILE"
fi

# Insert into mkdocs.yml nav if not already present
if ! grep -q "$DATE" mkdocs.yml; then
  # Use awk to insert new entry immediately after "  - Logs:" line
  awk -v date="$DATE" '
    /^  - Logs:/ {
      print $0
      print "      - " date ": logs/" date ".md"
      next
    }
    {print}
  ' mkdocs.yml > mkdocs.yml.tmp && mv mkdocs.yml.tmp mkdocs.yml

  echo "Added $DATE to mkdocs.yml nav (at top of Logs)"
else
  echo "Log $DATE already in mkdocs.yml nav"
fi
