{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
		parsecDeb = {
			url = "https://builds.parsecgaming.com/package/parsec-linux.deb";
			flake = false;
		};
		parsecMeta = {
			url = "https://builds.parsecgaming.com/channel/release/appdata/linux/latest";
			flake = false;
		};
	};

  outputs = { self, nixpkgs, parsecDeb, parsecMeta }:
	{
	    # Declare some local packages be available via self.packages
	    packages.x86_64-linux = let pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; }; in {
	     parsecgaming = pkgs.callPackage ./. { inherit parsecMeta parsecDeb; };
	 };
  defaultPackage.x86_64-linux = self.packages.x86_64-linux.parsecgaming;
};
}
