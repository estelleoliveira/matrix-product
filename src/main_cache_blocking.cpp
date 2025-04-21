#include <cassert>
#include <cstdlib>
#include <chrono>

#include <Kokkos_Core.hpp>
#include <fmt/core.h>

using Matrix = Kokkos::View<double**, Kokkos::LayoutRight>;

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

constexpr int BLOCK_SIZE_i = 16;
constexpr int BLOCK_SIZE_j = 32;
template <class AMatrixType, class BMatrixType, class CMatrixType>
auto matrix_product(double alpha, AMatrixType const& A, BMatrixType const& B, double beta, CMatrixType& C) -> void {
  static_assert(
    AMatrixType::rank() == 2 && BMatrixType::rank() == 2 && CMatrixType::rank() == 2, "Views must be of rank 2"
  );
  assert(A.extent(0) == C.extent(0));
  assert(B.extent(1) == C.extent(1));
  assert(A.extent(1) == B.extent(0));

/*Block extend on BLOCK_SIZE_i BLOCK_SIZE_j*/
  Kokkos::parallel_for(
    "dgemm_kernel_blocked",
    A.extent(0),
    KOKKOS_LAMBDA(int i) {
      for (int j_block = 0; j_block < int((B.extent(1)+BLOCK_SIZE_j-1)/BLOCK_SIZE_j); j_block++){
      for (int j = 0; j < BLOCK_SIZE_j; ++j) {
        int col = j_block * BLOCK_SIZE_j + j;
        double acc = 0.0;
        if (col >= int(B.extent(1))) continue;


        for (int k_block = 0; k_block < int((A.extent(0)+BLOCK_SIZE_i-1)/BLOCK_SIZE_i); k_block++){
        for (int k = 0; k < BLOCK_SIZE_i; ++k) {
          int kk = k_block * BLOCK_SIZE_i + k;
          if (kk >= int(A.extent(1))) continue;

          acc += alpha * A(i, kk) * B(kk, col);
        }
        }
        C(i, col) *= beta + acc;
      }
      }
    }
  );
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
  auto A = Matrix("A", m, k);
  auto B = Matrix("B", k, n);
  auto C = Matrix("C", m, n);

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
