defmodule Bolt.Mixfile do
  use Mix.Project

  def project do
    [app: :bolt,
     version: "0.1.4",
     elixir: "~> 1.4",
     package: package(),
     description: description(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/jessiahr/bolt",
     name: "Bolt",
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     mod: {Bolt.Application, [:redix]}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:redix, ">= 0.0.0"},
      {:poison, "~> 3.1"},
      {:cowboy, "~> 1.0"},
      {:plug, "~> 1.3.2"},
      {:uuid, "~> 1.1"},
      {:timex, "~> 3.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    A simple job queue backed by redis and built in elixir.
    """
  end

  defp package do
    # These are the default files included in the package
    [
      name: :bolt,
      files: ["lib", "priv", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Jessiah Ratliff"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/jessiahr/bolt"}
    ]
  end
end
