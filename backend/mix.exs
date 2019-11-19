defmodule Backend.Mixfile do
  use Mix.Project

  def project do
    [
      app: :backend,
      version: "0.0.1",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Backend.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.4"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_html, "~> 2.11"},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 1.0"},
      {:cowboy, "~> 1.0"},
      {:bamboo, "~> 1.3"},
      {:cors_plug, "~> 2.0"},
      {:dbstore, path: "../dbstore"},
      {:auth, path: "../auth"}
    ]
  end
end
