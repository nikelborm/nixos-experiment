{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      disko,
      ...
    }:
    {
      nixosConfigurations.xiaomi-A35S-laptop-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        # specialArgs is resolved before `config`, so these can be used in
        # `imports` without triggering infinite recursion
        specialArgs = { inherit inputs; };
        modules = [
          ./hardware-vm.nix
          ./configuration.nix
        ];
      };
    };
}
