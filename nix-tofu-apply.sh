#!/usr/bin/env nix-shell
#! nix-shell -i bash --pure

tofu init
tofu apply --auto-approve -compact-warnings

