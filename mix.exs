defmodule UeberauthDropbox.Mixfile do
  use Mix.Project

  def project do
    [app: :ueberauth_dropbox,
     name: "Ueberauth Dropbox",
     description: description(),
     package: package(),
     version: "0.1.1",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     source_url: "https://github.com/ryotsu/ueberauth_dropbox"
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :ueberauth, :oauth2]]
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
      {:oauth2, "~> 1.0 or ~> 2.0"},
      {:ueberauth, "~> 0.7.0"},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev], runtime: false},
    ]
  end


  defp description do
    "An Ueberauth strategy for using Dropbox"
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Mayank Tripathi"],
     licenses: ["MIT"],
     links: %{"GitHub": "https://github.com/ryotsu/ueberauth_dropbox"}]
  end
end
