cmake_minimum_required(VERSION 3.24)
project(cuda_thrust_intro LANGUAGES CXX CUDA)

# Require CUDA 12.0+
if(NOT DEFINED CMAKE_CUDA_STANDARD)
  set(CMAKE_CUDA_STANDARD 17)
  set(CMAKE_CUDA_STANDARD_REQUIRED ON)
endif()

# Target GPU architectures
# RTX 4070 SUPER is compute capability 8.9 (Ada). You can add others if needed.
set(CMAKE_CUDA_ARCHITECTURES 89)

# Warnings & optimization
if (MSVC)
  add_compile_options(/W4)
else()
  add_compile_options(-Wall -Wextra -Wno-unknown-pragmas)
endif()

set(SRC src/thrust_intro.cu)

add_executable(thrust_intro ${SRC})

# Enable separable compilation for larger projects
set_target_properties(thrust_intro PROPERTIES
  CUDA_SEPARABLE_COMPILATION ON
  CUDA_RESOLVE_DEVICE_SYMBOLS ON
)

# Optimize
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

# ---- CTest setup ----
include(CTest)         # safe even if BUILD_TESTING is off; defines BUILD_TESTING
if (BUILD_TESTING)
  enable_testing()
  # Run the program; test passes if exit code == 0
  add_test(NAME vector_add_run COMMAND vector_add)

  # (Optional) Fail if output doesn't contain "OK"
  set_tests_properties(vector_add_run
    PROPERTIES
      PASS_REGULAR_EXPRESSION "OK|Success|Passed"  # adjust to your program's output
      TIMEOUT 10
  )

  # (Optional) pick a GPU if you have multiple
  # set_tests_properties(vector_add_run PROPERTIES ENVIRONMENT "CUDA_VISIBLE_DEVICES=0")
endif()
