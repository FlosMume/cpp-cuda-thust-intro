#!/bin/bash
# check_cuda_starter_status.sh
# One-shot environment/build checker + GPU arch check + micro-benchmark
# For: cuda-starter-windows-wsl

set -u

echo "=== CUDA Starter Project Status ==="

have() { command -v "$1" >/dev/null 2>&1; }

section() { echo; echo "[$1] $2"; }

# 1) CUDA toolkit
section "1/7" "Checking CUDA toolkit (nvcc)…"
if have nvcc; then
  nvcc --version | sed -n 's/.*, release \(.*\),.*/CUDA Toolkit release \1/p'
else
  echo "❌ nvcc not found. Install CUDA Toolkit or add it to PATH."
fi

# 2) NVIDIA driver / GPU
section "2/7" "Checking NVIDIA driver & GPU…"
if have nvidia-smi; then
  echo "Driver:"
  nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | sed 's/^/  /'
  echo "GPU(s):"
  nvidia-smi --query-gpu=name,compute_cap --format=csv,noheader 2>/dev/null | sed 's/^/  /'
else
  echo "❌ nvidia-smi not found. Driver may be missing or WSL GPU not enabled."
fi

# 3) CMake
section "3/7" "Checking CMake…"
if have cmake; then
  cmake --version | head -n1
else
  echo "❌ cmake not found."
fi

# 4) Build artifacts
section "4/7" "Checking build artifacts…"
BIN="build/thrust_intro"
if [ -d build ]; then
  echo "✅ build/ directory found."
else
  echo "⚠️ build/ directory missing."
fi
if [ -f "$BIN" ]; then
  echo "✅ Binary found: $BIN"
else
  echo "⚠️ Binary not found. Build with:"
  echo "   cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j"
fi

# 5) Compare GPU compute capability vs CMAKE_CUDA_ARCHITECTURES
section "5/7" "Verifying GPU arch vs CMake setting…"
GPU_CC_RAW=""
GPU_ARCH_NUM=""
if have nvidia-smi; then
  # Take the first GPU's compute capability (e.g., 8.9)
  GPU_CC_RAW="$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null | head -n1 | tr -d ' ')"
  if [ -n "$GPU_CC_RAW" ]; then
    # Convert "8.9" -> "89"
    GPU_ARCH_NUM="${GPU_CC_RAW/./}"
    echo "Detected GPU compute capability: $GPU_CC_RAW  → arch code: $GPU_ARCH_NUM"
  else
    echo "⚠️ Could not read compute capability from nvidia-smi."
  fi
else
  echo "⚠️ Skipping (no nvidia-smi)."
fi

CMAKE_ARCHES=""
if [ -f CMakeLists.txt ]; then
  # Extract set(CMAKE_CUDA_ARCHITECTURES 89;…)
  CMAKE_ARCHES="$(sed -n 's/^[[:space:]]*set( *CMAKE_CUDA_ARCHITECTURES *\([^)]*\)).*/\1/p' CMakeLists.txt | tr -d ' ' )"
  if [ -n "$CMAKE_ARCHES" ]; then
    echo "CMake CMAKE_CUDA_ARCHITECTURES: $CMAKE_ARCHES"
    if [ -n "$GPU_ARCH_NUM" ]; then
      # Check membership (handles lists like 86;89;90)
      if echo "$CMAKE_ARCHES" | tr ';' '\n' | grep -qx "$GPU_ARCH_NUM"; then
        echo "✅ CMake targets your GPU arch ($GPU_ARCH_NUM)."
      else
        echo "⚠️ Your GPU ($GPU_ARCH_NUM) is not in CMAKE_CUDA_ARCHITECTURES."
        echo "   → Consider updating CMakeLists.txt, e.g.: set(CMAKE_CUDA_ARCHITECTURES $GPU_ARCH_NUM)"
      fi
    fi
  else
    echo "⚠️ Could not find CMAKE_CUDA_ARCHITECTURES in CMakeLists.txt."
  fi
else
  echo "⚠️ CMakeLists.txt not found."
fi

# 6) Quick functional test
section "6/7" "Functional test (run thrust_intro)…"
if [ -x "$BIN" ]; then
  "$BIN"
else
  echo "⚠️ Skipping test (binary missing or not executable)."
fi

# 7) Micro-benchmark (warm-up + timed runs)
section "7/7" "Micro-benchmark (warm-up + timed runs)…"
if [ -x "$BIN" ]; then
  WARMUP=1
  RUNS=10
  echo "Warming up ($WARMUP run)…"
  for _ in $(seq 1 $WARMUP); do "$BIN" >/dev/null 2>&1; done

  echo "Timing $RUNS runs…"
  total_ms=0
  best_ms=0
  worst_ms=0
  for i in $(seq 1 $RUNS); do
    start_ns=$(date +%s%N)
    "$BIN" >/dev/null 2>&1
    end_ns=$(date +%s%N)
    dur_ms=$(( (end_ns - start_ns) / 1000000 ))
    if [ $i -eq 1 ]; then
      best_ms=$dur_ms; worst_ms=$dur_ms
    else
      [ $dur_ms -lt $best_ms ] && best_ms=$dur_ms
      [ $dur_ms -gt $worst_ms ] && worst_ms=$dur_ms
    fi
    total_ms=$((total_ms + dur_ms))
    printf "  Run %2d: %4d ms\n" "$i" "$dur_ms"
  done
  avg_ms=$(( total_ms / RUNS ))
  echo "—"
  echo "Avg:  ${avg_ms} ms   Best: ${best_ms} ms   Worst: ${worst_ms} ms  (over $RUNS runs)"
else
  echo "⚠️ Skipping benchmark (binary missing or not executable)."
fi

echo
echo "=== Status Check Complete ==="
