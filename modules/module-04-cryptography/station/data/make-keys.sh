#!/bin/sh
# Generate two PGP identities (Alice and Bob) in the local keyring, with no
# passphrase (%no-protection) so the lab flows without pinentry prompts.
set -e

gen() {  # gen <name> <email>
    gpg --batch --gen-key >/dev/null 2>&1 <<EOF
%no-protection
Key-Type: RSA
Key-Length: 2048
Name-Real: $1
Name-Email: $2
Expire-Date: 0
%commit
EOF
    echo "  generated key for $1 <$2>"
}

if gpg --list-keys alice@lab >/dev/null 2>&1; then
    echo "Keys already exist. Delete ~/.gnupg to start over."
else
    echo "Generating PGP keypairs (RSA 2048)..."
    gen "Alice" "alice@lab"
    gen "Bob"   "bob@lab"
    echo "Done."
fi
