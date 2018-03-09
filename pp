#!/usr/bin/env bash

set -o errexit
set -o nounset

OPTIND=1
OUTPUT_FILE=a.out

while getopts ":o:" opt; do
    case $opt in
        o)
            OUTPUT_FILE="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

INPUT_FILE=${*:$OPTIND:1}
TEMP_DIR=".${0##*/}-$$";
mkdir "$TEMP_DIR";
trap 'rm -rf $TEMP_DIR' EXIT
TEMP_FILE="$TEMP_DIR/$INPUT_FILE.ll"

if [ -z "$INPUT_FILE" ]; then
    echo "Must provide an input file"
    exit 1
fi

while read -r line; do
    echo "#$line" >> "$OUTPUT_FILE"
done < "$INPUT_FILE"

cat << EOF >> "$TEMP_FILE"

; ModuleID = '$INPUT_FILE'
target triple = "$(clang -v 2>&1 | awk -F' ' '/Target/{print $NF}')"

; Function Attrs: nounwind ssp uwtable
define i32 @main() #0 {
  %1 = alloca i32, align 4
  store i32 0, i32* %1, align 4
  ret i32 0
}

EOF

clang -Wno-override-module "$TEMP_FILE" -o "$OUTPUT_FILE"
