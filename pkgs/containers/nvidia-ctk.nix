{ buildGoModule, fetchFromGitHub }:

let
  # From https://gitlab.com/nvidia/container-toolkit/container-toolkit/-/blob/03cbf9c6cd26c75afef8a2dd68e0306aace80401/Makefile#L54
  cliVersionPackage = "github.com/NVIDIA/nvidia-container-toolkit/internal/info";
in
buildGoModule rec {
  pname = "nvidia-ctk";
  version = "1.16.2";

  src = fetchFromGitHub {
    owner = "nvidia";
    repo = "nvidia-container-toolkit";
    rev = "v${version}";
    hash = "sha256-ldEBF+5zuJAyDSUVnMPja2BvdMCNMDkp0Ye5+qFEm14=";
  };

  # subPackages = [ "cmd/nvidia-ctk" ];
  subPackages = [
    "cmd/nvidia-cdi-hook"
    "cmd/nvidia-container-runtime"
    "cmd/nvidia-container-runtime.cdi"
    "cmd/nvidia-container-runtime-hook"
    "cmd/nvidia-container-runtime.legacy"
    "cmd/nvidia-ctk"
  ];

  vendorHash = null;

  ldflags = [
    "-s"
    "-w"
    "-extldflags=-Wl,-z,lazy"
    "-X"
    "${cliVersionPackage}.version=${version}"
  ];

  meta.mainProgram = "nvidia-ctk";
}
