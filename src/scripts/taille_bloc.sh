#!/bin/bash
export LC_NUMERIC=C #force utilisation du point comme séparateur décimal

#vérification des arguments d'entrée pour l'execution du script bash
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <executable> <nb_threads>"
  exit 1
fi

EXE=$1
THREADS=$2

MATRIX_SIZE=2000
REF_TIME=0

#résultat
> ../results/blocs_var.txt

#plage de taille de blocs
BLOCK_SIZES=(16 32 64 128)

for BLOCK_I in "${BLOCK_SIZES[@]}"; do
  for BLOCK_J in "${BLOCK_SIZES[@]}"; do
    for BLOCK_K in "${BLOCK_SIZES[@]}"; do
      echo "Test BLOCK_SIZE_i = $BLOCK_I, BLOCK_SIZE_j = $BLOCK_J, BLOCK_SIZE_k = $BLOCK_K"

      # remplacement dans le code source
      sed -i "s/^constexpr int BLOCK_SIZE_i = .*/constexpr int BLOCK_SIZE_i = $BLOCK_I;/" ../main_cache_blocking.cpp
      sed -i "s/^constexpr int BLOCK_SIZE_j = .*/constexpr int BLOCK_SIZE_j = $BLOCK_J;/" ../main_cache_blocking.cpp
      sed -i "s/^constexpr int BLOCK_SIZE_j = .*/constexpr int BLOCK_SIZE_j = $BLOCK_K;/" ../main_cache_blocking.cpp

      # Compilation
      cmake --build ../../build

      # Execution
      OUTPUT=$(OMP_NUM_THREADS=$THREADS OMP_PROC_BIND=true OMP_PLACES=cores $EXE $MATRIX_SIZE $MATRIX_SIZE $MATRIX_SIZE)
      echo "$OUTPUT"

      TIME=$(echo "$OUTPUT" | grep -oP 'Elapsed time in matrix product : \K[0-9]+\.[0-9]{6}')
      echo "Extracted time : $TIME"


      if [[ $BLOCK_I -eq 16 && $BLOCK_J -eq 16 ]]; then
        REF_TIME=$TIME
        SPEEDUP=1.0
        echo "Bloc 16x16x16 utilisé comme référence ($TIME s)"
      else
        SPEEDUP=$(echo "$REF_TIME / $TIME" | bc -l)
      fi

      printf "Speedup : %.2fx\n" "$SPEEDUP"
      echo "$BLOCK_I $BLOCK_J $BLOCK_K $TIME $SPEEDUP" >> "../results/blocs_var.txt"
    done
  done
done

python3 plot_blocs_var.py