{ applyPatches
, bspSrc
, gitRepos
, kernel
, l4tMajorMinorPatchVersion
, lib
, runCommand
, stdenv
, pkgs
, ...
}:
let
  patchedBsp = applyPatches {
    name = "patchedBsp";
    src = bspSrc;
    patches = [
      ./Makefile.diff
    ];
  };

  mkCopyProjectCommand = project: ''
    mkdir -p $out/${project.name}
    cp --no-preserve=all -r ${project}/. $out/${project.name}
  '';

  l4t-oot-projects = [
    (gitRepos.hwpm.overrideAttrs { name = "hwpm"; })
    (applyPatches {
      name = "nvidia-oot";
      src = gitRepos.nvidia-oot;
      patches = [
        ./0001-rtl8822ce-Fix-Werror-address.patch
        ./0002-sound-Fix-include-path-for-tegra-virt-alt-include.patch
      ];
    })
    (gitRepos.nvgpu.overrideAttrs { name = "nvgpu"; })
    (pkgs.lib.overrideDerivation (applyPatches {
      name = "nvdisplay";
      src = gitRepos.nvdisplay;
      patches = [
        ./0001-nvidia-drm-Guard-nv_dev-in-nv_drm_suspend_resume.patch
        ./0001-rename-backlight-device-by-name.patch
      ];
    }) (old: { NIX_CFLAGS_COMPILE = "-fno-stack-protector -Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration"; }))
     # pkgs.lib.overrideDerivation (pkgs.dmenu) (old: { NIX_CFLAGS_COMPILE = "-O3 -march=native"; })
    (applyPatches {
      name = "nvethernetrm";
      src = gitRepos.nvethernetrm;
      # Some directories in the git repo are RO.
      # This works for L4T b/c they use different output directory
      postPatch = ''
        chmod -R u+w osi
      '';
    })
  ];

  l4t-oot-modules-sources = runCommand "l4t-oot-sources" { }
    (
      # Copy the Makefile
      ''
        mkdir -p "$out"
        cp "${patchedBsp}/source/Makefile" "$out/Makefile"
      ''
      # copy the projects
      + lib.strings.concatMapStringsSep "\n" mkCopyProjectCommand l4t-oot-projects
      # See bspSrc/source/source_sync.sh symlink at end of file
      + ''
        ln -srf $out/nvethernetrm $out/nvidia-oot/drivers/net/ethernet/nvidia/nvethernet/nvethernetrm
      ''
    );
in
stdenv.mkDerivation (finalAttrs: {
  pname = "l4t-oot-modules";
  version = "${l4tMajorMinorPatchVersion}";
  src = l4t-oot-modules-sources;

  inherit kernel;

  nativeBuildInputs = finalAttrs.kernel.moduleBuildDependencies;

  # See bspSrc/source/Makefile
  makeFlags = finalAttrs.kernel.makeFlags ++ [
    "KERNEL_HEADERS=${finalAttrs.kernel.dev}/lib/modules/${finalAttrs.kernel.modDirVersion}/source"
    "KERNEL_OUTPUT=${finalAttrs.kernel.dev}/lib/modules/${finalAttrs.kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
  ];

  buildFlags = [ "modules" ];
  installTargets = [ "modules_install" ];
})
