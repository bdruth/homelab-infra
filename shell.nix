let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-24.05";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in

pkgs.mkShellNoCC {
  packages = with pkgs; [
    opentofu
    ansible
    netcat
    dig
  ];

  # drone env vars
  PM_API_TOKEN_SECRET = builtins.getEnv "PM_API_TOKEN_SECRET";
  PM_API_TOKEN_ID = builtins.getEnv "PM_API_TOKEN_ID";
  AWS_ACCESS_KEY_ID = builtins.getEnv "AWS_ACCESS_KEY_ID";
  AWS_SECRET_ACCESS_KEY = builtins.getEnv "AWS_SECRET_ACCESS_KEY";
  PIHOLE_WEB_PASSWORD_HASH = builtins.getEnv "PIHOLE_WEB_PASSWORD_HASH";
  DNSDIST_CONSOLE_KEY = builtins.getEnv "DNSDIST_CONSOLE_KEY";
  ansible_pihole_vars_main_yml = builtins.getEnv "ansible_pihole_vars_main_yml";
  common_tfbackend = builtins.getEnv "common_tfbackend";
  dnsdist_tfstate_key = builtins.getEnv "dnsdist_tfstate_key";
  blue_pihole_tfstate_key = builtins.getEnv "blue_pihole_tfstate_key";
  green_pihole_tfstate_key = builtins.getEnv "green_pihole_tfstate_key";
  dnsdist_tfvars = builtins.getEnv "dnsdist_tfvars";
  pihole_blue_tfvars = builtins.getEnv "pihole_blue_tfvars";
  pihole_green_tfvars = builtins.getEnv "pihole_green_tfvars";
  pihole_default_tfvars = builtins.getEnv "pihole_default_tfvars";

  shellHook = ''
    # Mark variables which are modified or created for export.
    set -a
    source ${toString ./.env}
    set +a
  '';
}
