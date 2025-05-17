{ deb-builder }:
deb-builder {
  sourceName = "cuda-cuxxfilt";
  outputs = [
    "out"
    "bin"
    "dev"
    "doc"
    "include"
    "static"
    "lib"
  ];
  releaseInfo = {
    license = "CUDA Toolkit";
    name = "CUPTI";
  };
}
