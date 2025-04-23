#!/bin/bash
export LC_NUMERIC=C #force utilisation du point comme séparateur décimal

#vérification des arguments d'entrée pour l'execution du script bash
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <executable> <nb_threads>"
    exit 1
fi

EXE=$1
THREADS=$2
MATRIX_SIZE=3000
REF_TIME=0

#résultat
> ../results/perf_layout_var.txt

# Déf les layouts possibles
LAYOUTS=("LayoutRight" "LayoutLeft")

for LAYOUT_A in "${LAYOUTS[@]}"; do
    for LAYOUT_B in "${LAYOUTS[@]}"; do
        for LAYOUT_C in "${LAYOUTS[@]}"; do
            echo "Test Layout_A = $LAYOUT_A, Layout_B = $LAYOUT_B, Layout_C = $LAYOUT_C"
            
            # Modifier les layouts dans le code source
            sed -i "s/using MatrixA = Kokkos::View<double\*\*, Kokkos::[^>]*>/using MatrixA = Kokkos::View<double**, Kokkos::$LAYOUT_A>/" ../main.cpp
            sed -i "s/using MatrixB = Kokkos::View<double\*\*, Kokkos::[^>]*>/using MatrixB = Kokkos::View<double**, Kokkos::$LAYOUT_B>/" ../main.cpp
            sed -i "s/using MatrixC = Kokkos::View<double\*\*, Kokkos::[^>]*>/using MatrixC = Kokkos::View<double**, Kokkos::$LAYOUT_C>/" ../main.cpp
            
            # Compilation
            cmake --build ../../build
            
            # Execution
            OUTPUT=$(sudo OMP_NUM_THREADS=$THREADS OMP_PROC_BIND=true OMP_PLACES=cores perf stat -e cache-misses,cache-references,LLC-load-misses,L1-dcache-load-misses $EXE $MATRIX_SIZE $MATRIX_SIZE $MATRIX_SIZE 2>&1)
            echo "$OUTPUT"
            
            TIME=$(echo "$OUTPUT" | grep -oP 'Elapsed time in matrix product : \K[0-9]+\.[0-9]{6}')
            echo "Extracted time : $TIME"
            
            if [[ "$LAYOUT_A" == "LayoutRight" && "$LAYOUT_B" == "LayoutRight" && "$LAYOUT_C" == "LayoutRight" ]]; then
                REF_TIME=$TIME
                SPEEDUP=1.0
                echo "Configuration de référence ($TIME s)"
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
            echo "$LAYOUT_A $LAYOUT_B $LAYOUT_C $TIME $SPEEDUP $ATOM_CACHE_MISSES $CORE_CACHE_MISSES $ATOM_CACHE_REF $CORE_CACHE_REF $ATOM_LLC_MISSES $CORE_LLC_MISSES $CORE_L1_MISSES" >> "../results/perf_layout_var.txt"
        done
    done
done

python3 Layout.py