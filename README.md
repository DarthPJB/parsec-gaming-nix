# parsec-gaming-nix
An implementation of parsecgaming (aka parsec) for NixOS users.

## usage
### as system-configuration
With a flake enabled system you can easily implement this in your own enviroment with 
``` nix
{
  inputs = 
  {
    parsecgaming.url = "github:DarthPJB/parsec-gaming-nix";
  };
}
```
and 
``` nix
{
  environment.systemPackages = with pkgs; 
  [
       inputs.parsecgaming.packages.x86_64-linux.parsecgaming
  ];
}
```
### in a shell
simply run ```nix shell github:DarthPJB/parsec-gaming-nix#parsecgaming``` on a flake-enabled nixos system

## Known issues

Due to parsec removing previous builds from their servers with each new release; this flake will fail to build at some point in the future - while caching the inputs via hydra or cachix may help; the proper solution is to update this flake with the URL to their latest build.

To do this simply edit the default.nix file - updating the url as appropriate. see [here](https://github.com/DarthPJB/parsec-gaming-nix/blob/6610278873cef9371b338788c06cb0b53d860b25/default.nix#L9), and [here](https://github.com/DarthPJB/parsec-gaming-nix/blob/6610278873cef9371b338788c06cb0b53d860b25/default.nix#L23);

# Important reminder.
You should fork this, use this, and make use of this in any way you want - please don't rely on me to maintain it (although I will do my best to do so).

Credit goes to @matthewcroughan for the original nix-file, and @nixinator for helping with repackaging.

