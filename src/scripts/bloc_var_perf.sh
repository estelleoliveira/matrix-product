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
> ../results/perf_bloc_var.txt

#plage de taille de blocs
BLOCK_SIZES=(16 32 64 128)

for BLOCK_I in "${BLOCK_SIZES[@]}"; do
  for BLOCK_J in "${BLOCK_SIZES[@]}"; do
    for BLOCK_K in "${BLOCK_SIZES[@]}"; do

        echo "Test BLOCK_SIZE_i = $BLOCK_I, BLOCK_SIZE_j = $BLOCK_J, BLOCK_SIZE_k = $BLOCK_K"

        # remplacement dans le code source
        sed -i "s/^constexpr int BLOCK_SIZE_i = .*/constexpr int BLOCK_SIZE_i = $BLOCK_I;/" ../main_cache_blocking.cpp
        sed -i "s/^constexpr int BLOCK_SIZE_j = .*/constexpr int BLOCK_SIZE_j = $BLOCK_J;/" ../main_cache_blocking.cpp
        sed -i "s/^constexpr int BLOCK_SIZE_k = .*/constexpr int BLOCK_SIZE_k = $BLOCK_K;/" ../main_cache_blocking.cpp

        # Compilation
        cmake --build ../../build

        # Execution
        OUTPUT=$(sudo OMP_NUM_THREADS=$THREADS OMP_PROC_BIND=true OMP_PLACES=cores perf stat -e cache-misses,cache-references,LLC-load-misses,L1-dcache-load-misses $EXE $MATRIX_SIZE $MATRIX_SIZE $MATRIX_SIZE 2>&1)
        echo "$OUTPUT"

        TIME=$(echo "$OUTPUT" | grep -oP 'Elapsed time in matrix product : \K[0-9]+\.[0-9]{6}')
        echo "Extracted time : $TIME"


        if [[ $BLOCK_I -eq 16 && $BLOCK_J -eq 16 && $BLOCK_K -eq 16 ]]; then
        REF_TIME=$TIME
        SPEEDUP=1.0
        echo "Bloc 16x16x16 utilisé comme référence ($TIME s)"
        else
        SPEEDUP=$(echo "$REF_TIME / $TIME" | bc -l)
        fi

        printf "Speedup : %.2fx\n" "$SPEEDUP"

        ATOM_CACHE_MISSES=$(echo "$OUTPUT" | awk '/cache-misses/ && /cpu_atom/ {gsub(",", "", $1); print $1}')
        CORE_CACHE_MISSES=$(echo "$OUTPUT" | awk '/cache-misses/ && /cpu_core/ {gsub(",", "", $1); print $1}')
        
        ATOM_CACHE_REF=$(echo "$OUTPUT" | awk '/cache-references/ && /cpu_atom/ {gsub(",", "", $1); print $1}')
        CORE_CACHE_REF=$(echo "$OUTPUT" | awk '/cache-references/ && /cpu_core/ {gsub(",", "", $1); print $1}')

        ATOM_LLC_MISSES=$(echo "$OUTPUT" | awk '/LLC-load-misses/ && /cpu_atom/ {gsub(",", "", $1); print $1}')
        CORE_LLC_MISSES=$(echo "$OUTPUT" | awk '/LLC-load-misses/ && /cpu_core/ {gsub(",", "", $1); print $1}')
        CORE_L1_MISSES=$(echo "$OUTPUT" | awk '/L1-dcache-load-misses/ && /cpu_core/ {gsub(",", "", $1); print $1}')
        echo "$BLOCK_I$BLOCK_J$BLOCK_K $TIME $SPEEDUP $ATOM_CACHE_MISSES $CORE_CACHE_MISSES $ATOM_CACHE_REF $CORE_CACHE_REF $ATOM_LLC_MISSES $CORE_LLC_MISSES $CORE_L1_MISSES" >> "../results/perf_bloc_var.txt"
    done
  done
done

python3 bloc_var_perf.py