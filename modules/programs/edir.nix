{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    types
    ;

  cfg = config.programs.edir;
in
{

  options.programs.edir = {
    enable = mkEnableOption "edir";
    package = mkPackageOption pkgs "edir" { };
    flags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Extra flags to pass to edir.

        See <https://github.com/kpbaks/edir#command-line-options> for the full
        list of options.

      '';
      example = [
        "--all"
        "--group-dirs-first"
        "--recurse"
        "--trash"
      ];
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."edir-flags.conf".text = builtins.concatStringsSep "\n" cfg.flags;
  };
}
