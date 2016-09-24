#!/bin/bash
set -e
cd /crawl/crawl-ref/source
exec gosu games "$@"
