{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkOption types;

  cfg = config.programs.tuios;
  tomlFormat = pkgs.formats.toml { };

  mkShellIntegrationOption =
    option:
    option
    // {
      default = false;
      example = true;
    };
in
{
  meta.maintainers = [
    lib.maintainers.kpbaks
  ];

  options.programs.tuios = {
    enable = lib.mkEnableOption "tuios";

    package = lib.mkPackageOption pkgs "tuios" { };

    systemd.enable = lib.mkEnableOption "tuios systemd integration" // {
      default = true;
    };

    # TODO: use this
    theme = lib.mkOption {
      type = types.str;
      default = null;
      example = "wombat";
      description = ''
        Use `tuios --list-themes` to get list of available themes.
      '';
    };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          appearance = {
            border_style = "rounded";
            dockbar_position = "bottom";
          }
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/tuios/config.toml`.

        See <https://github.com/Gaurav-Gosain/tuios/blob/v${cfg.package.version}/docs/CONFIGURATION.md> for the full
        list of configuration options.
      '';
    };

    # TODO: use `tuios attach`
    attachExistingSession = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to attach to the default session after being autostarted if a tuios session already exists.

        Variable is checked in `auto-start` script. Requires shell integration to be enabled to have effect.
      '';
    };

    exitShellOnExit = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to exit the shell when tuios exits after being autostarted.

        Variable is checked in `auto-start` script. Requires shell integration to be enabled to have effect.
      '';
    };

    enableBashIntegration = mkShellIntegrationOption (
      lib.hm.shell.mkBashIntegrationOption { inherit config; }
    );

    enableFishIntegration = mkShellIntegrationOption (
      lib.hm.shell.mkFishIntegrationOption { inherit config; }
    );

    enableZshIntegration = mkShellIntegrationOption (
      lib.hm.shell.mkZshIntegrationOption { inherit config; }
    );

    enableNushellIntegration = mkShellIntegrationOption (
      lib.hm.shell.mkNushellIntegrationOption { inherit config; }
    );
  };

  config =
    let
      shellIntegrationEnabled = (
        cfg.enableBashIntegration
        || cfg.enableZshIntegration
        || cfg.enableFishIntegration
        || cfg.enableNushellIntegration
      );
    in
    mkIf cfg.enable (
      lib.mkMerge [
        {
          home.packages = [ cfg.package ];
          xdg.configFile."tuios/config.toml".source = tomlFormat.generate "tuios-config" cfg.settings;

          # programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
          #   eval "$(${lib.getExe cfg.package} setup --generate-auto-start bash)"
          # '';

          # programs.zsh.initContent = mkIf cfg.enableZshIntegration (
          #   lib.mkOrder 200 ''
          #     eval "$(${lib.getExe cfg.package} setup --generate-auto-start zsh)"
          #   ''
          # );

          # programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
          #   eval (${lib.getExe cfg.package} setup --generate-auto-start fish | string collect)
          # '';

          home.sessionVariables = mkIf shellIntegrationEnabled {
            TUIOS_AUTO_ATTACH = if cfg.attachExistingSession then "true" else "false";
            TUIOS_AUTO_EXIT = if cfg.exitShellOnExit then "true" else "false";
          };

          warnings =
            lib.optional (cfg.attachExistingSession && !shellIntegrationEnabled) ''
              You have enabled `programs.tuios.attachExistingSession`, but none of the shell integrations are enabled.
              This option will have no effect.
            ''
            ++ lib.optional (cfg.exitShellOnExit && !shellIntegrationEnabled) ''
              You have enabled `programs.tuios.exitShellOnExit`, but none of the shell integrations are enabled.
              This option will have no effect.
            '';
        }
        (mkIf cfg.systemd.enable {
          systemd.user.services.tuios = {
            Unit = {
              Description = "tuios session daemon";
              Documentation = "https://github.com/Gaurav-Gosain/tuios/tree/v${cfg.package.version}/docs";
              After = [ "graphical-session.target" ];
            };

            Service = {
              ExecStart = "${lib.getExe cfg.package} daemon";
              Restart = "on-failure";
            };

            Install.WantedBy = [ "graphical-session.target" ];
          };
        })
      ]
    );
}
