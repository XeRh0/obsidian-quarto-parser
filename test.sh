#!/usr/bin/env bash

printf "[Running tests!]\n";

for DIR in tests/*; do

  printf "> Test suite: [${DIR##*/}]\n";

  for TEST in $DIR/in/*; do
    printf "Test \"${TEST##*/}\": ";

    cat $TEST | ./obsidian-to-quarto.pl > tmp.txt;
    diff tmp.txt $DIR/out/out_${TEST##*_} #> /dev/null;

    if [[ $? -eq 0 ]]; then
      echo -e "[\u001b[32mGOOD\u001b[37m]";
    else
      echo -e "[\u001b[31mFAIL\u001b[37m]";
    fi
  done 
done

if [[ -f "tmp.txt" ]]; then
  rm "tmp.txt";
fi
