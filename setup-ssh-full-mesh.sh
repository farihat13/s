#!/bin/bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    echo "Example: ./setup-ssh-full-mesh.sh servers.txt"
    echo "Example content of servers.txt:"
    printf '%s\n' "user1@host1" "user2@host2" "user3@host3"
    exit 1
fi

MY_KEY="$HOME/.ssh/cloudlab"
COMMON_KEY_NAME="id_ed25519"
TMP_KEY_DIR="/tmp/ssh_key_setup"
INPUT_FILE="$1"

# Read server list from input file
SERVERS=()
while IFS= read -r line || [ -n "$line" ]; do
    FULL=$(echo "$line" | xargs) # Trim leading and trailing whitespaces
    SERVERS+=("$FULL")
done < "$INPUT_FILE"

if [ ${#SERVERS[@]} -lt 2 ]; then
  echo "Need at least 2 servers for full mesh setup."
  exit 1
fi

echo "Starting SSH key-based full mesh setup among servers:"
printf '\t%s\n' "${SERVERS[@]}"

mkdir -p "$TMP_KEY_DIR"
chmod 700 "$TMP_KEY_DIR"


# Step 1: Generate SSH keys on each server and fetch them
for FULL in "${SERVERS[@]}"; do
    USER="${FULL%@*}"
    HOST="${FULL#*@}"

    # check if key already exists in tmp dir
    if [ -f "$TMP_KEY_DIR/${HOST}_${COMMON_KEY_NAME}" ]; then
        echo "Key exists in $TMP_KEY_DIR, skipping key gen for '$FULL'"
        continue
    fi

    echo "Generating key on '$FULL'"
    ssh -o IdentitiesOnly=yes -i "$MY_KEY" "$FULL" bash -s <<EOF
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        if [ ! -f ~/.ssh/${COMMON_KEY_NAME} ]; then
            ssh-keygen -t ed25519 -f ~/.ssh/${COMMON_KEY_NAME} -N "" -C "$FULL"
            chmod 600 ~/.ssh/${COMMON_KEY_NAME}
        fi
EOF
    scp -i "$MY_KEY" "$FULL:~/.ssh/${COMMON_KEY_NAME}" "$TMP_KEY_DIR/${HOST}_${COMMON_KEY_NAME}"
    scp -i "$MY_KEY" "$FULL:~/.ssh/${COMMON_KEY_NAME}.pub" "$TMP_KEY_DIR/${HOST}_${COMMON_KEY_NAME}.pub"
done

# exit 0

# Step 2: Distribute public keys and setup config
for TARGET in "${SERVERS[@]}"; do
    TARGET_USER="${TARGET%@*}"
    TARGET_HOST="${TARGET#*@}"
    echo "Setting up authorized_keys and ssh config on $TARGET_HOST"

    for i in "${!SERVERS[@]}"; do
        SOURCE="${SERVERS[$i]}"
        SOURCE_USER="${SOURCE%@*}"
        SOURCE_HOST="${SOURCE#*@}"
        ALIAS="n$i" # assign alias based on index, e.g., n0, n1, n2...

        if [ "$SOURCE" != "$TARGET" ]; then

            echo -e "\tCopying public key from $SOURCE ($ALIAS)"
            PUBKEY_FILE="$TMP_KEY_DIR/${SOURCE_HOST}_${COMMON_KEY_NAME}.pub"
            PUBKEY=$(<"$PUBKEY_FILE")

            ssh -o IdentitiesOnly=yes -i "$MY_KEY" "$TARGET" bash -s <<EOF
                mkdir -p ~/.ssh
                chmod 700 ~/.ssh

                # Add pubkey if not already present
                grep -qxF "$PUBKEY" ~/.ssh/authorized_keys 2>/dev/null || echo "$PUBKEY" >> ~/.ssh/authorized_keys
                chmod 600 ~/.ssh/authorized_keys

                # Setup config entry if not present
                if ! grep -q "^Host ${SOURCE_HOST}\$" ~/.ssh/config 2>/dev/null; then
                    {
                        echo "Host ${ALIAS}"
                        echo "  HostName ${SOURCE_HOST}"
                        echo "  User ${SOURCE_USER}"
                        echo "  IdentityFile ~/.ssh/${COMMON_KEY_NAME}"
                    } >> ~/.ssh/config
                    chmod 600 ~/.ssh/config
                fi
EOF
        fi
    done
done

echo "Done! SSH full-mesh setup is complete."
