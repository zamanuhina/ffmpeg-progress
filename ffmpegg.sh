#!/bin/bash

ALL_ARGS=( "$@" )

INPUT_FILE=""
while [[ $# -gt 0 ]]
do
  if [ "$1" = "-i" ]; then
    INPUT_FILE="$2"
  fi
  shift
done

OUT_LOG="out.log"
rm -f $OUT_LOG && touch $OUT_LOG

duration=$(ffmpeg -i "$INPUT_FILE" 2>&1 | sed -n "s/.* Duration: \([^,]*\), start: .*/\1/p")
fps=$(ffmpeg -i "$INPUT_FILE" 2>&1 | sed -n "s/.*, \(.*\) fps.*/\1/p")
hours=$(echo "$duration" | cut -d":" -f1)
hours=${hours##+(0)}
minutes=$(echo "$duration" | cut -d":" -f2)
seconds=${seconds##+(0)}
seconds=$(echo "$duration" | cut -d":" -f3)
seconds=${seconds##+(0)}
seconds=${seconds%.*}
T=$((hours*3600+minutes*60+seconds))
FRAMES=$(echo "$T*$fps" | bc | cut -d"." -f1)

echo ""

ffmpeg -vstats_file $OUT_LOG -y "${ALL_ARGS[@]}" &> /dev/null &

PID=$!

LAST_PRC=0

while ps -p "$PID">/dev/null; do
  currentframe=$(tail -n 1 $OUT_LOG | awk '/frame=/ { print $6 }')
  if [[ -n "$currentframe" ]]; then
    PRC=$(echo "scale=0; $currentframe * 100 / $FRAMES" | bc -l)
    if [ "$PRC" = "0" ]; then PRC=${LAST_PRC}; else LAST_PRC=${PRC}; fi
    LINE_PRC=""
    for ((i=1;i<=100;i++)); do
      if [ "${PRC}" -lt "$i" ]; then
        LINE_PRC="${LINE_PRC}.";
      else
        LINE_PRC="${LINE_PRC}#";
      fi
    done
    echo -ne " ${PRC}% [ ${LINE_PRC} ]\r"
    sleep 1
  fi
done

LINE_PRC=""
for ((i=1;i<=100;i++)); do
  LINE_PRC="${LINE_PRC}#";
done
echo -ne " 100% [ ${LINE_PRC} ]\r"

rm -f $OUT_LOG

echo ""
echo ""
