#!/bin/bash
set -e

echo "Installing Elixir and Erlang..."

# Install dependencies
apt-get update
apt-get install -y curl gnupg

# Add Erlang repository
curl -fsSL https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/erlang.gpg
echo "deb https://packages.erlang-solutions.com/ubuntu $(lsb_release -cs) contrib" | tee /etc/apt/sources.list.d/erlang.list

# Install Erlang and Elixir
apt-get update
apt-get install -y esl-erlang elixir

# Install Hex package manager and Phoenix framework
su - dev -c 'mix local.hex --force && mix local.rebar --force && mix archive.install hex phx_new --force'

echo "Elixir installation complete!"