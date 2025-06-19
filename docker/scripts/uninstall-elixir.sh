#!/bin/bash
set -e

echo "Uninstalling Elixir and Erlang..."

# Check if Elixir is installed
if ! command -v elixir &> /dev/null; then
    echo "Elixir doesn't appear to be installed. Nothing to do."
    exit 0
fi

# Remove Elixir and Erlang packages
apt-get purge -y elixir esl-erlang

# Remove repository
rm -f /etc/apt/sources.list.d/erlang.list
rm -f /etc/apt/trusted.gpg.d/erlang.gpg
apt-get update

# Remove Mix archives and data
rm -rf /home/dev/.mix

echo "Elixir and Erlang uninstallation complete!"