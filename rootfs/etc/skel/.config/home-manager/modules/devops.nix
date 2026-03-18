{ pkgs, ... }:

{

 home.packages = with pkgs; [
    #python3
    #python3Packages.proxmoxer
    ansible
    ansible-lint
    opentofu
  ];

###############################################
# GIT
###############################################

  programs.git = {
      enable = true;
      settings = {
        aliases = {
          ci = "commit";
          co = "checkout";
          s = "status";
        };
        # user = {
        #   name = "${gituser}";
        #   email = "${gitemail}";
        # };
      };
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
      };
    };

  programs.gitui.enable = true;
  programs.gh.enable = true;

}