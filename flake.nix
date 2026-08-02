{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      ...
    }:
    {
      nixosConfigurations.xiaomi-A35S-laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Both commented because the final layout turned out to be different in
          # small details, becase I couldn't just wipe the disk and apply disko
          # config to it
          # disko.nixosModules.disko
          # ./disko-config.nix
          ./disko-fixed-render.nix
          ./configuration.nix
        ];
      };
    };
}
