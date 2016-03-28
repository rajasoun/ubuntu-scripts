#!/usr/bin/env sh

# npm install -g markdown-index
dir=$1
markdown-index  $dir  > Index.md

# grip Index.md 0.0.0.0
