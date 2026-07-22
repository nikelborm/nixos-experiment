read -rs -p "LUKS passphrase: " pw; echo
printf %s "$pw" > /tmp/secret.key; unset pw

nix --experimental-features "nix-command flakes" \
  run github:nix-community/disko -- \
  --mode destroy,format,mount --show-trace ./disko-config.nix
