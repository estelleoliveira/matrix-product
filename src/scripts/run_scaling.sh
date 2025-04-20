#!/bin/bash
export LC_NUMERIC=C #force utilisation du point comme séparateur décimal


#vérification des arguments d'entrée pour l'execution du script bash
if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <executable> <M> <N> <K>"
  exit 1
fi

EXE=$1
M=$2
N=$3
K=$4

#on récupère le nombre de threads maximal pour executer la boucle sur ce nombre
MAX_THREADS=$(lscpu -p | egrep -v '^#' | sort -u -t, -k 2,4 | wc -l)
REF_TIME=0

#on fait tourner le code sur le nombre de threads max, on extrait le temps, on calcule le speedup
for i in $(seq 1 $MAX_THREADS); do
  echo "------ Threads : $i ------"
  OUTPUT=$(OMP_NUM_THREADS=$i OMP_PROC_BIND=true OMP_PLACES=cores $EXE $M $N $K)
  echo "$OUTPUT"

  TIME=$(echo "$OUTPUT" | grep -oP 'Elapsed time in matrix product : \K[0-9]+\.[0-9]{6}') #extraction du temps depuis l'output
  echo "Extracted time: $TIME" 

  if [[ $i -eq 1 ]]; then
    REF_TIME=$TIME #stock du temps ref pour 1 thread
    echo "Speedup : 1.0x"
    printf "Time used for Time_ref: %.6f s\n" "$TIME"
  else
    SPEEDUP=$(echo "$REF_TIME / $TIME" | bc -l) #calcul du speedup T1/TN, strong scaling
    printf "Speedup : %.2fx\n" "$SPEEDUP"
  fi
done