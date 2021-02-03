#!/bin/bash

if git status | grep -E 'new file|modified' > /dev/null 2>&1; then
    git add .
    git commit -m "update on $(date '+%Y/%m/%d')"
    git push
fi
