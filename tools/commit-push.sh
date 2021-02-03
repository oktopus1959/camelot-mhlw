#!/bin/bash

git add .
if git status | grep 'new file:' > /dev/null 2>&1; then
    git commit -m "update on $(date '+%Y/%m/%d')"
    git push
fi
