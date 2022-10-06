#!/bin/bash

# Run the test.rb script for the number cruncher under gdb.
#
# `ruby` needs resolve to the correct version, modify PATH to ensure this.
gdb -q \
    -ex 'set breakpoint pending on' \
    -ex 'b process' \
    -ex 'source /root/gdb_macros_for_ruby' \
    -ex run --args ruby ./test.rb
