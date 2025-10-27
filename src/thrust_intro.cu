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
  const int N = 1<<20;
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
