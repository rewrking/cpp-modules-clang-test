#!/usr/bin/env bash

# not yet :(
# clang++ -std=c++20 -stdlib=libc++ -fmodules -fmodules-ts -fbuiltin-module-map -Xclang -emit-module-interface -o build/modules-test -c main.cpp
# -fno-module-lazy
# -flang-info-include-translate

CC="clang++"

CXX_FLAGS="-std=c++20 -O3 -Wall -Wextra -Wpedantic -fdiagnostics-color=always -Isrc"

OUTPUT_DIR="build"
MODULE_ID="e545ab910d1ddd09"

ERROR_COLOR="\x1b[0;91m"
COLOR="\x1b[0;96m"
RESET="\x1b[0m"

SYSTEM_HEADER_UNITS=
INPUT_FILES=$(find src -type f -name '*.cc')

count=0
input_file_count="$(printf "$SYSTEM_HEADER_UNITS $INPUT_FILES\n" | sed 's/ /\n/g' | wc -l)"
((total_count=input_file_count+1))

do_cmd()
{
	CMD=$1
	echo $CMD
	$CMD
	RESULT=$?
	if [[ $RESULT != 0 ]]; then
		printf "${ERROR_COLOR}ERROR:$RESET $CMD\n"
		exit 1
	fi
}

do_cmd "which $CC"

precompile_module()
{
	IN_MODULES=
	for mod in "$2";
	do
		IN_MODULES+="-fmodule-file=$mod=$mod.cc.pcm "
	done
	((count=count+1))
	printf "[$count/$total_count] ${COLOR}src/$1$RESET\n"
	do_cmd "$CC -x c++ -MT $OUTPUT_DIR/$1.pcm -MMD -MP -MF $OUTPUT_DIR/$1.d $CXX_FLAGS --precompile $IN_MODULES -o $OUTPUT_DIR/$1.pcm -c src/$1"
	# do_cmd "$CC -x c++ $CXX_FLAGS -o $OUTPUT_DIR/$1.o -c src/$1"
}

$CC --version | grep -i "$CC"

rm -rf $OUTPUT_DIR
mkdir $OUTPUT_DIR

printf "\n"

sleep 2

# System Header-units

# Note: These must be ordered correctly

# Local Header-units
# flags_header_unit "header.hpp"
# Modules
# flags_module_unit "test-impl.cpp"
precompile_module "Hello.cc"
precompile_module "Main.cc" "Hello"

# Root
# precompile_module "main.cc"
# flags_module_unit "main.cpp"

# do_cmd "$CC -std=c++20 src/Main.cc -fmodule-file=Hello=Hello.pcm $(find $OUTPUT_DIR -type f -name '*.pcm') -o $OUTPUT_DIR/modules-test"

# Link
((count=count+1))
printf "[$count/$total_count] ${COLOR}Linking $OUTPUT_DIR/modules-test$RESET\n"
do_cmd "$CC -o $OUTPUT_DIR/modules-test $(find $OUTPUT_DIR -type f -name '*.pcm')"

printf "\n"

./$OUTPUT_DIR/modules-test

exit 0
