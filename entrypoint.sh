#!/bin/bash
set -e

exec gosu builduser "$@"
