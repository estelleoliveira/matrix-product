#!/bin/bash
export LC_NUMERIC=C #force utilisation du point comme séparateur décimal


#vérification des arguments d'entrée pour l'execution du script bash
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <executable> <nb_threads>"
  exit 1
fi

EXE=$1
THREADS=$2

REF_TIME=0

#plage de taille de matrices à tester
START_SIZE=100
END_SIZE=1000
STEP=100

> ../results/size_var.txt
#on fait tourner le code sur le nombre de threads max, on extrait le temps, on calcule le speedup
for i in $(seq $START_SIZE $STEP $END_SIZE); do
  echo "------ Matrix size : $i x $i ------"
  OUTPUT=$(OMP_NUM_THREADS=$THREADS OMP_PROC_BIND=true OMP_PLACES=cores $EXE $i $i $i)
  echo "$OUTPUT"

  TIME=$(echo "$OUTPUT" | grep -oP 'Elapsed time in matrix product : \K[0-9]+\.[0-9]{6}') #extraction du temps depuis l'output
  echo "Extracted time: $TIME" 

  if [[ $i -eq $START_SIZE ]]; then
    REF_TIME=$TIME #stock du temps ref pour 1 thread
    echo "Speedup : 1.0x"
    printf "Time used for Time_ref: %.6f s\n" "$TIME"
    echo "$i $TIME 1.0" >> ../results/size_var.txt
  else
    SPEEDUP=$(echo "$REF_TIME / $TIME" | bc -l) #calcul du speedup T1/TN, strong scaling
    printf "Speedup : %.2fx\n" "$SPEEDUP"
    echo "$i $TIME $SPEEDUP" >> ../results/size_var.txt
  fi
done

python3 plot_matrix_var.py