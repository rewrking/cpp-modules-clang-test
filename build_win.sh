#!/usr/bin/env bash

# not yet :(
# clang++ -std=c++20 -stdlib=libc++ -fmodules -fmodules-ts -fbuiltin-module-map -Xclang -emit-module-interface -o build/modules-test -c main.cpp
# -fno-module-lazy
# -flang-info-include-translate

PATH="/c/Program Files/LLVM/bin:/c/msys64/usr/bin:PATH"

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

# do_cmd "which $CC"

precompile_module()
{
	TYPE="${3:-"c++-module"}"
	IN_MODULES=
	if [[ "$2" != '' ]]; then
		for mod in $2; do
			IN_MODULES+="-fmodule-file=$mod=$OUTPUT_DIR/$mod.cc.pcm "
		done
	fi
	((count=count+1))
	printf "[$count/$total_count] ${COLOR}src/$1$RESET\n"
	do_cmd "$CC -x $TYPE $CXX_FLAGS --precompile $IN_MODULES -o $OUTPUT_DIR/$1.pcm -c src/$1"
}

compile_module()
{
	TYPE="${3:-"c++-module"}"
	IN_MODULES=
	if [[ "$2" != '' ]]; then
		for mod in $2; do
			IN_MODULES+="-fmodule-file=$mod=$OUTPUT_DIR/$mod.cc.pcm "
		done
	fi
	((count=count+1))
	printf "[$count/$total_count] ${COLOR}src/$1$RESET\n"
	do_cmd "$CC -x $TYPE -MT $OUTPUT_DIR/$1.o -MMD -MP -MF $OUTPUT_DIR/$1.d $CXX_FLAGS $IN_MODULES -o $OUTPUT_DIR/$1.o -c src/$1"
}

$CC --version

rm -rf "$OUTPUT_DIR"
mkdir "$OUTPUT_DIR"

printf "\n"

sleep 2

# Note: These must be ordered correctly

# Precompile Phase

# System Header-units
# Local Header-units
# Modules
precompile_module "Hello.cc"
# precompile_module "Main.cc" "Hello" "c++"

# Compile Phase
compile_module "Hello.cc"

# Root
compile_module "Main.cc" "Hello" "c++"

# do_cmd "$CC -std=c++20 src/Main.cc -fmodule-file=Hello=Hello.pcm $(find $OUTPUT_DIR -type f -name '*.pcm') -o $OUTPUT_DIR/modules-test"

# Link
((count=count+1))
printf "[$count/$total_count] ${COLOR}Linking $OUTPUT_DIR/modules-test.exe$RESET\n"
do_cmd "$CC -o $OUTPUT_DIR/modules-test.exe $OUTPUT_DIR/Hello.cc.o $OUTPUT_DIR/Main.cc.o"

printf "\n"

./$OUTPUT_DIR/modules-test

exit 0
