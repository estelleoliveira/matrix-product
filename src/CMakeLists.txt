add_executable(top.matrix_product-origin)
target_sources(top.matrix_product-origin PRIVATE main.cpp)
target_compile_options(top.matrix_product-origin PRIVATE -Wall -Wextra -Wpedantic)
target_link_libraries(top.matrix_product-origin PRIVATE Kokkos::kokkos fmt::fmt)

add_executable(top.matrix_product-blocked)
target_sources(top.matrix_product-blocked PRIVATE main_cache_blocking.cpp)
target_compile_options(top.matrix_product-blocked PRIVATE -Wall -Wextra -Wpedantic)
target_link_libraries(top.matrix_product-blocked Kokkos::kokkos fmt::fmt)