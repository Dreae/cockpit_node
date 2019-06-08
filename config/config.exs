# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :cockpit_node, CockpitNode.Socket,
    address: "localhost",
    port: 1337,
    key: "g4ngn0hv7/T+pI5TEY8hCH84UzfWBs3GRAMQMEn591tNMD5lBG+P1YOISvCwHzN4",
    server_id: 1

config :logger, :console, format: "$time [$level] $message\n"

import_config "#{Mix.env}.exs"
