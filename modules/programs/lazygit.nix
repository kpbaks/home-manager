{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.lazygit;

  yamlFormat = pkgs.formats.yaml { };

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

in
{
  meta.maintainers = [
    lib.hm.maintainers.kalhauge
    lib.maintainers.khaneliman
  ];

  options.programs.lazygit = {
    enable = lib.mkEnableOption "lazygit, a simple terminal UI for git commands";

    package = lib.mkPackageOption pkgs "lazygit" { nullable = true; };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      defaultText = lib.literalExpression "{ }";
      example = lib.literalExpression ''
        {
          gui.theme = {
            lightTheme = true;
            activeBorderColor = [ "blue" "bold" ];
            inactiveBorderColor = [ "black" ];
            selectedLineBgColor = [ "default" ];
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/lazygit/config.yml`
        on Linux or on Darwin if [](#opt-xdg.enable) is set, otherwise
        {file}`~/Library/Application Support/lazygit/config.yml`.
        See
        <https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md>
        for supported values.
      '';
    };

    changeDirOnExit = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Change directory to the repository you have focused in lazygit
        when you quit the session.

        See
        <https://github.com/jesseduffield/lazygit#changing-directory-on-exit>
        for more details of how this can be used.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.file."Library/Application Support/lazygit/config.yml" =
      mkIf (cfg.settings != { } && (isDarwin && !config.xdg.enable))
        {
          source = yamlFormat.generate "lazygit-config" cfg.settings;
        };

    xdg.configFile."lazygit/config.yml" =
      mkIf (cfg.settings != { } && !(isDarwin && !config.xdg.enable))
        {
          source = yamlFormat.generate "lazygit-config" cfg.settings;
        };

    programs.bash.initExtra =
      mkIf cfg.changeDirOnExit
        # bash
        ''
          function lazygit() {
            export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
            ${cfg.package}/bin/lazygit "$@"

            if [ -f "$LAZYGIT_NEW_DIR_FILE" ]; then
              read dir < "$LAZYGIT_NEW_DIR_FILE"
              cd "$dir"
              rm -f "$LAZYGIT_NEW_DIR_FILE" > /dev/null
            fi
          }
        '';

    programs.bash.initContent =
      mkIf cfg.changeDirOnExit
        # zsh
        ''
          function lazygit() {
            export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
            ${cfg.package}/bin/lazygit "$@"

            if [ -f "$LAZYGIT_NEW_DIR_FILE" ]; then
              read dir < "$LAZYGIT_NEW_DIR_FILE"
              cd "$dir"
              rm -f "$LAZYGIT_NEW_DIR_FILE" > /dev/null
            fi
          }
        '';

    programs.fish.interactiveShellInit =
      mkIf cfg.changeDirOnExit
        # fish
        ''
          function lazygit
            set -x LAZYGIT_NEW_DIR_FILE ~/.lazygit/newdir
            ${cfg.package}/bin/lazygit $argv

            if test -f $LAZYGIT_NEW_DIR_FILE
              read -l dir < $LAZYGIT_NEW_DIR_FILE
              builtin cd $dir
              command rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
            end
          end
        '';

    programs.nushell.extraConfig =
      mkIf cfg.changeDirOnExit
        # nu
        ''
          def --env --wrapped lazygit [...args] {
            $env.LAZYGIT_NEW_DIR_FILE = ~/.lazygit/newdir
            ${cfg.package}/bin/lazygit $args

            try {
              let dir = open --raw $env.LAZYGIT_NEW_DIR_FILE
              cd $dir
              rm -f $env.LAZYGIT_NEW_DIR_FILE > /dev/null
            }
          }
        '';

    programs.ion.initExtra =
      mkIf cfg.changeDirOnExit
        # ion
        ''
          fn lazygit args:[str]
            export LAZYGIT_NEW_DIR_FILE = ~/.lazygit/newdir

            if test -f $LAZYGIT_NEW_DIR_FILE
              read dir < $LAZYGIT_NEW_DIR_FILE
              cd $dir
              rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
            end
          end
        '';
  };
}
