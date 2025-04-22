#include <cassert>
#include <cstdlib>
#include <chrono>
#include <iostream> //stdcout debug

#include <Kokkos_Core.hpp>
#include <fmt/core.h>

using MatrixR = Kokkos::View<double**, Kokkos::LayoutRight>;
using MatrixL = Kokkos::View<double**, Kokkos::LayoutLeft>;

template <class MatrixType>
auto matrix_init(MatrixType& M) -> void {
  static_assert(2 == MatrixType::rank(), "View must be of rank 2");

  Kokkos::parallel_for(
    "init",
    M.extent(0),
    KOKKOS_LAMBDA(int i) {
      for (int j = 0; j < int(M.extent(1)); ++j) {
        M(i, j) = drand48();
      }
    }
  );
}

constexpr int BLOCK_SIZE_i = 32;
constexpr int BLOCK_SIZE_j = 32;
constexpr int BLOCK_SIZE_k = 128;
template <class AMatrixType, class BMatrixType, class CMatrixType>
auto matrix_product(double alpha, AMatrixType const& A, BMatrixType const& B, double beta, CMatrixType& C) -> void {
  static_assert(
    AMatrixType::rank() == 2 && BMatrixType::rank() == 2 && CMatrixType::rank() == 2, "Views must be of rank 2"
  );
  assert(A.extent(0) == C.extent(0)); //i Aik Cij
  assert(B.extent(1) == C.extent(1)); //j Bkj Cij
  assert(A.extent(1) == B.extent(0)); //k Aik Bkj

/*Block extend on BLOCK_SIZE_i BLOCK_SIZE_j*/
  Kokkos::parallel_for(
    "dgemm_kernel_blocked",
    Kokkos::MDRangePolicy<Kokkos::Rank<2>>({0, 0}, {(A.extent(0) + BLOCK_SIZE_i - 1)/ BLOCK_SIZE_i, (B.extent(1) + BLOCK_SIZE_j - 1) / BLOCK_SIZE_j}),
    KOKKOS_LAMBDA(int i_block, int j_block) {
      int i_start = i_block * BLOCK_SIZE_i; //indice coin supérieur gauche du bloc i
      int j_start = j_block * BLOCK_SIZE_j; //indice coin supérieur gauche du bloc j

      /*On crée ici un cache blocking de manière à se déplacer sur des blocs, le long des lignes de A et des colonnes de B, 
      on block aussi au niveau de k --> composante colonne de A et ligne de B, ainsi on fait des multiplication de petites matrices*/
      for (int i = i_start; i < std::min(i_start + BLOCK_SIZE_i, int(A.extent(0))); ++i) {
        for (int j = j_start; j < std::min(j_start + BLOCK_SIZE_j, int(B.extent(1))); ++j) {
          double acc = 0.0;
          for (int k_block = 0; k_block < int(A.extent(1)); k_block += BLOCK_SIZE_k) {
          for (int k = 0; k < std::min(k_block + BLOCK_SIZE_k, int(A.extent(1))); ++k) {
            acc += alpha * A(i, k) * B(k, j);
          }
          }
          C(i,j) *= beta + acc;
        }
      }
    }
  );
    //Affichage de C pour comparer avec main //débug
  /*if (int(C.extent(0)) < 5 && int(C.extent(1)) < 5){
  for (int i = 0; i < int(C.extent(0)); ++i) {
    for (int j = 0; j < int(C.extent(1)); ++j) {
        std::cout << C(i, j) << " ";
    }
    std::cout << std::endl;
  }
  }*/
}

auto main(int argc, char* argv[]) -> int {
  if (argc < 4) {
    fmt::print("Usage: {} <M> <N> <K>\n", argv[0]);
    return -1;
  }
  int m = std::atoi(argv[1]);
  int n = std::atoi(argv[2]);
  int k = std::atoi(argv[3]);

  // Known seed for deterministic RNG
  srand48(42);

  Kokkos::initialize(argc, argv);
  {
  int nb_threads = Kokkos::DefaultExecutionSpace().concurrency();
  fmt::print("Nombre de threads disponibles : {}\n", nb_threads);
  auto A = MatrixR("A", m, k);
  auto B = MatrixL("B", k, n);
  auto C = MatrixR("C", m, n);

  double alpha = drand48();
  matrix_init(A);
  matrix_init(B);
  double beta = drand48();
  matrix_init(C);

  Kokkos::fence();
  auto start_time = std::chrono::high_resolution_clock::now();
  matrix_product(alpha, A, B, beta, C);
  auto end_time = std::chrono::high_resolution_clock::now();
  Kokkos::fence();

  double elapsed = std::chrono::duration<double>(end_time - start_time).count();
  double gflops = (2.0 * m * n * k) / (elapsed * 1e9);

  printf("Elapsed time in matrix product : %.6f s - Performance: %.6f GFLOP/s\n", elapsed, gflops);
  }
  Kokkos::finalize();

  return 0;
}
