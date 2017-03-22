#!/bin/sh
toolchain/clang/bin/clang --target=msp430 -save-temps -integrated-as -c file.cpp $@

