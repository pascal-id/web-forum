#!/bin/bash
./clean.sh
./build.sh forum $1 || exit 1
./build.sh news $1 || exit 1
./build.sh stats $1 || exit 1
./build.sh topic $1 || exit 1
./build.sh auth $1 || exit 1
