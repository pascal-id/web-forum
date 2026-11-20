#!/bin/bash
./clean.sh
./build.sh auth $1 || exit 1
./build.sh forumpascal $1 || exit 1
./build.sh search $1 || exit 1
