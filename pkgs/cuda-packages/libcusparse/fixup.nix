# NOTE: All fixups must be at least binary functions to avoid callPackage adding override attributes.
{ lib, libnvjitlink, cudaAtLeast }:
prevAttrs: {
  buildInputs = prevAttrs.buildInputs or [ ]
    ++ (lib.lists.optionals (cudaAtLeast "12") [ (lib.getLib libnvjitlink) ]);
}
