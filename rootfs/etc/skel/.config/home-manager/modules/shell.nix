{ pkgs, ... }:

{


###############################################
# TERMINAL
###############################################

  # https://github.com/alacritty/alacritty/tree/master#configuration
  programs.alacritty = {
      enable = true;
      settings = {
        program = "fish";
        window = {
          #blur = true;
          opacity = 0.98;
          dimensions = {
            lines = 40;
            columns = 120;
          };
          padding = {
            x = 10;
            y = 5;
          };
          dynamic_padding = false;
          decorations = "full";
        };
        font = {
          size = 14.0;
          normal.family = "FiraCode Nerd Font Mono";
          bold.family = "FiraCode Nerd Font Mono";
          italic.family = "FiraCode Nerd Font Mono";
          bold_italic.family = "FiraCode Nerd Font Mono";
        };
        colors = {
#           primary = {
#             background = "#141414";
#             foreground = "#c7ccd1";
#           };
#           cursor = {
#             text = "#1c2023";
#             cursor = "#c7ccd1";
#           };
#           normal = {
#             black   = "#1c2023";
#             red     = "#c7ae95";
#             green   = "#95c7ae";
#             yellow  = "#aec795";
#             blue    = "#ae95c7";
#             magenta = "#c795ae";
#             cyan    = "#95aec7";
#             white   = "#c7ccd1";
#            };
#           bright = {
#             black   = "#747c84";
#             red     = "#c7ae95";
#             green   = "#95c7ae";
#             yellow  = "#aec795";
#             blue    = "#ae95c7";
#             magenta = "#c795ae";
#             cyan    = "#95aec7";
#             white   = "#f3f4f5";
#           };
        };
      };
    };


  # https://codeberg.org/dnkl/foot/src/branch/master/foot.ini
  programs.foot = {
    enable = true;

    main = {
      shell = "fish";
      font = "FiraCodeNerdFontMono:size=14";
      dpi-aware = "yes";
      pad = "5x5";
      gamma-correct-blending = "no";
    };

    mouse = {
      hide-when-typing = "yes";
    };

    tweak = {
      font-monospace-warn = "no";
    };

    colors-dark = {
      alpha = "0.95";
      cursor = "181818 56d8c9";
      background = "181818";
      foreground = "d8d8d8";
      regular0 = "181818";
      regular1 = "ac4242";
      regular2 = "90a959";
      regular3 = "f4bf75";
      regular4 = "6a9fb5";
      regular5 = "aa759f";
      regular6 = "75b5aa";
      regular7 = "d8d8d8";
      bright0 = "6b6b6b";
      bright1 = "c55555";
      bright2 = "aac474";
      bright3 = "feca88";
      bright4 = "82b8c8";
      bright5 = "c28cb8";
      bright6 = "93d3c3";
      bright7 = "f8f8f8";
    };
  };

  programs.kitty = {
    enable = false;
    package = pkgs.kitty;
    font.name = "JetBrainsMono Nerd Font";
    font.size = 14;
    settings = {
      scrollback_lines = 2000;
      wheel_scroll_min_lines = 1;
      window_padding_width = 6;
      confirm_os_window_close = 0;
      background_opacity = "0.95";
    };
  };


###############################################
# MULTIPLEXER
###############################################

  programs.tmux = {
    enable = false;
    mouse = true;
    terminal = "xterm-256color";
    extraConfig = ''
      set -g default-shell ${pkgs.fish}/bin/fish
      bind-key -n Home send Escape "OH"
      bind-key -n End send Escape "OF"
    '';
  };

  programs.zellij = {
    enable = false;
    enableFishIntegration = true;
    enableBashIntegration = true;
  };


###############################################
# SHELL
###############################################

  programs.bash = {
    enable = false;
    shellAliases = {
      l = "ls -l";
      lst = "eza --sort newest -l";
      cat = "bat --paging=never";

      gcl = "git clone --recursive";
      gs = "git status";
      gd = "git diff";
      ga = "git add";
      gaa = "git add --all";
      gc = "git commit -v";
      gp = "git push";

      # ns = "sudo nixos-rebuild switch --flake ~/nix-config#${hostname}";
      # hs = "home-manager switch --flake ~/nix-config#${username}@${hostname}";
    };
    #initExtra = "exec fish";
  };

  programs.fish = {
    enable = true;
    shellInit = ''
      set fish_greeting # Disable greeting
      fish_vi_key_bindings
    '';
    shellAliases = {
      l = "ls -l";
      lst = "eza --sort newest -l";
      cat = "bat -p --paging=never";
      #ns = "sudo nixos-rebuild switch --flake ~/nix-config#${hostname}";
      #hs = "home-manager switch --flake ~/nix-config#${username}@${hostname}";
    };
    plugins = [
      { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }
    ];
  };

  programs.zsh = {
    enable = false;
  };

  programs.nushell = {
      enable = false;
  };


###############################################
# SHELL PROMPT
###############################################

  # https://starship.rs/config/
  programs.starship = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;

      settings = {
        add_newline = true;
        scan_timeout = 5;

        format= lib.concatStrings [
          "$shlvl"
          "$username"
          "$hostname"
          "$shell"
          "$time"
          "$nix_shell"
          "$git_branch"
          "$git_commit"
          "$git_state"
          "$git_status"
          "$directory"
          "$jobs"
          "$cmd_duration"
          "$line_break"
          "$character"
        ];

        shlvl = {
          disabled = false;
          format = ''[\[$shlvl\]]($style) '';
          #symbol = "";
          style = "red";
        };

        shell = {
          disabled = false;
          format = ''[ use](italic dimmed) [$indicator]($style) [at](italic dimmed) '';
          style = "bright-red bold";
          fish_indicator = "󰈺";
          bash_indicator = "󱆃";
        };

        time = {
          disabled = false;
          format = ''[$time]($style) [in](italic dimmed) '';
          style = "bright-red";
        };

        username = {
          disabled = false;
          show_always = true;
          format = "[$user]($style)";
          style_user = "bright-green bold";
          style_root = "bright-red bold";
        };

        hostname = {
          style = "bright-blue bold";
          format = "[ on ](italic dimmed)[$ssh_symbol$hostname]($style)";
          ssh_only = false;
        };

        nix_shell = {
          symbol = " ";
          format = "[$symbol$name]($style) ";
          style = "bright-purple bold";
        };

        git_branch = {
          only_attached = true;
          format = "[$symbol $branch]($style) ";
          symbol = "";
          style = "bright-yellow bold";
        };

        git_commit = {
          only_detached = true;
          format = "[$hash]($style) ";
          style = "bright-yellow bold";
        };

        git_state = {
          style = "bright-purple bold";
        };

        git_status = {
          style = "bright-green bold";
        };

        directory = {
          read_only = " 🔒";
          style = "bright-white bold";
          truncation_length = 3;
          truncate_to_repo = true;
        };

        jobs = {
          style = "bright-green bold";
        };

        cmd_duration = {
          format = ''\([took](italic dimmed) [$duration]($style)\)'';
          style = "bright-green";
        };

        line_break = {
          disabled = false;
        };

        character = {
          disabled = false;
          #success_symbol = "   [󰜴](bright-green bold) ";
          success_symbol = "  [❯](bright-blue bold)[❯](bright-white bold)[❯](bright-red bold)";
          error_symbol = "  [✗](bright-red bold)";
        };
      };
    };


###############################################
# SHELL UTILS
###############################################

  programs = {

    # Modern cd
    zoxide = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
      enableNushellIntegration = false;
    };

    # Modern ls
    eza = {
      enable = true;
      enableAliases = true;
      icons = true; # make sure nerd fonts are installed on the system
    };

    # Modern cat
    bat = {
      enable = true;
    };

    # General-purpose command-line fuzzy finder
    fzf = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
    };

    # Command-line JSON processor
    jq.enable = true;

    # Recursively search the current directory for a regex pattern
    ripgrep.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    yazi = {
      enable = true;
      enableBashIntegration	= true;
      enableFishIntegration = true;
      enableNushellIntegration = false;
    };
  
  };


###############################################
# FONTS
###############################################

  fonts.fontconfig.enable = true;
  fonts.fontDir.enable = true;

#   home.packages = with pkgs; [
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    font-awesome
  ];


###############################################
# SHELL APPS
###############################################

  home.packages = with pkgs; [
    fd
    just
    curl
    wget
    tldr
    htop
    btop
    killall
    p7zip
    lsof
    fastfetch
  ];

}
