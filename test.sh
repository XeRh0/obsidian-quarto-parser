#!/usr/bin/env bash

printf "[Running tests!]\n";

for DIR in tests/*; do

  printf "> Test suite: ${DIR##*/}\n";

  for TEST in $DIR/in/*; do
    printf "Test \"${TEST##*/}\": ";

    cat $TEST | ./obsidian-to-quarto.pl > tmp.txt;
    diff tmp.txt $DIR/ref/${TEST##*/};

    if [[ $? -eq 0 ]]; then
      echo "[GOOD]";
    else
      echo "[FAIL]";
    fi
  done
done 
