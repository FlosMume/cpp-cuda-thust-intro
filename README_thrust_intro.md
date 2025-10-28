# cpp-cuda-thust-intro

GPU “Hello Thrust” — concise C++ examples using NVIDIA **Thrust**, a high-level CUDA parallel algorithms library.

This repository demonstrates how to write GPU programs in modern C++ using Thrust’s STL-like API.  
It includes simple examples of `transform`, `zip_iterator`, `device_vector`, and functor-based parallel computation.

---

## 🚀 Example: SAXPY with `thrust::transform`

```cpp
#include <cstdio>
#include <thrust/device_vector.h>
#include <thrust/transform.h>
#include <thrust/iterator/zip_iterator.h>
#include <thrust/tuple.h>

struct saxpy_functor {
  float a;
  __host__ __device__
  float operator()(const thrust::tuple<float,float>& t) const {
    return a * thrust::get<0>(t) + thrust::get<1>(t);
  }
};

int main(){
  const int N = 1 << 20;
  thrust::device_vector<float> x(N, 1.f), y(N, 2.f), z(N);

  saxpy_functor f{3.f};
  auto first = thrust::make_zip_iterator(thrust::make_tuple(x.begin(), y.begin()));
  auto last  = thrust::make_zip_iterator(thrust::make_tuple(x.end(),   y.end()));
  thrust::transform(first, last, z.begin(), f);

  float z0 = z[0], zN = z[N-1];
  printf("z[0]=%.1f  z[N-1]=%.1f  (expect 5.0)\n", z0, zN);
  printf("Success!\n");
  return 0;
}
```

Output:
```
z[0]=5.0  z[N-1]=5.0  (expect 5.0)
Success!
```

---

## 🧩 Topics
- CUDA  
- Thrust (NVIDIA)  
- GPU computing  
- Parallel programming  
- C++ / CMake / WSL2  
- Examples: transform · zip iterator · device vector  

---

## ⚙️ Build & Run

```bash
# Configure
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build -j

# Run
./build/thrust_intro
```

> ✅ Requires: CUDA 12.0+, a GPU with Compute Capability ≥ 8.9 (e.g. RTX 4070 SUPER), CMake 3.24+, and a C++17 compiler.

---

## 📂 Repository structure
```
cpp-cuda-thust-intro/
├── src/
│   └── thrust_intro.cu
├── CMakeLists.txt
├── README.md
└── check_thrust_intro_status.sh
```

---

## 🧠 Learning focus
- Understand how Thrust abstracts GPU kernels into STL-like functions.
- Learn `transform` with zip iterators to apply operations on multiple device vectors.
- Practice building CUDA C++ projects with CMake on Linux/WSL2.

---

## 📜 License
MIT License © 2025 [Samuel Huang (FlosMume)](https://github.com/FlosMume)
