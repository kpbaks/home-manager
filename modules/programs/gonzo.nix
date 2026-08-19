{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.programs.gonzo;
  gonzo = lib.getExe cfg.package;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.maintainers.kpbaks ];

  options = {
    programs.gonzo = {
      enable = lib.mkEnableOption "gonzo, TUI based log analysis tool";
      package = lib.mkPackageOption pkgs "gonzo" { };
      settings = lib.mkOption {
        inherit (yamlFormat) type;
        default = { };
        # https://github.com/control-theory/gonzo/blob/main/examples/config.yml
        example = lib.literalExpression ''
          {
            follow = true;
            update-interval = "1s";
            log-buffer = 1000;
            skin = "dracula";
          }
        '';
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/gonzo/config.yml`.

          See <https://github.com/control-theory/gonzo/tree/main#configuration-file>
          for supported values.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ gonzo ];

    # https://github.com/control-theory/gonzo/blob/main/examples/config.yml
    xdg.configFile."gonzo/config.yml" = lib.mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "gonzo-config.yml" cfg.settings;
    };

    # Install https://github.com/kpbaks/nixpkgs/pull/new/gonzo/install-custom-log-formats to ~/.config/gonzo/formats
    xdg.configFile."gonzo/formats" = {
      source = "${gonzo}/share/formats";
      recursive = true;
    };
  };
}
