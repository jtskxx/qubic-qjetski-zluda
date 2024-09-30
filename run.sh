#!/bin/bash

# Set up Zluda environment
export LD_LIBRARY_PATH="/root/zluda/target/release:${LD_LIBRARY_PATH}"
export LD_PRELOAD="/root/zluda/target/release/libzluda.so"

./qli-Client
