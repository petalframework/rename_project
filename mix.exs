defmodule RenameProject.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rename_project,
      version: "0.1.0",
      elixir: "~> 1.14",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp description do
    """
    For thoroughly renaming your Elixir projects
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["PetalFramework"],
      links: %{github: "https://github.com/petalframework/rename_project"}
    ]
  end

  defp deps do
    [
      {:excoveralls, "~> 0.6", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
