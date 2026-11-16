defmodule Mix.Tasks.Rename do
  @shortdoc "Renames an Elixir/Phoenix project across all naming conventions"

  @moduledoc """
  Renames an Elixir/Phoenix project's module names, OTP app names,
  and matching file/directory paths.

  ## Usage

      mix rename OldName NewName [options]

  ## Examples

      # Preview changes without modifying files
      mix rename AshPhoenixStarter AcmePortal --dry-run

      # Rename the project
      mix rename AshPhoenixStarter AcmePortal

      # Customize ignored directories or target path
      mix rename AshPhoenixStarter AcmePortal --starting-directory ./my_app --ignore-directories priv
  """

  use Mix.Task

  @switches [
    dry_run: :boolean,
    ignore_directories: :keep,
    ignore_files: :keep,
    starting_directory: :string,
    include_extensions: :keep,
    include_files: :keep
  ]

  @aliases [
    d: :dry_run
  ]

  @impl Mix.Task
  def run(args \\ []) do
    {parsed, positional, invalid} = OptionParser.parse(args, strict: @switches, aliases: @aliases)

    cond do
      invalid != [] ->
        invalid_flags = Enum.map_join(invalid, ", ", fn {flag, _} -> flag end)
        Mix.shell().error("Invalid option(s): #{invalid_flags}\n")
        print_usage_error()

      match?([old_name, new_name] when is_binary(old_name) and is_binary(new_name), positional) ->
        [old_name, new_name] = positional
        options = format_options(parsed)

        execute_rename({old_name, new_name}, options)

      true ->
        print_usage_error()
    end
  end

  # --- Private Helpers ---

  defp execute_rename({old_name, new_name}, options) do
    case RenameProject.run({old_name, new_name}, options) do
      {:ok, report} ->
        print_dry_run_report(report)

      :ok ->
        Mix.shell().info([:green, "Successfully renamed #{old_name} to #{new_name}!"])

      {:error, reason} ->
        Mix.shell().error("Rename failed: #{reason}")
    end
  end

  defp format_options(parsed) do
    list_keys = [:ignore_directories, :ignore_files, :include_extensions, :include_files]

    grouped_lists =
      parsed
      |> Keyword.take(list_keys)
      |> Enum.group_by(fn {k, _v} -> k end, fn {_k, v} -> v end)
      |> Map.to_list()

    scalar_opts = Keyword.take(parsed, [:dry_run, :starting_directory])

    Keyword.merge(grouped_lists, scalar_opts)
  end

  defp print_dry_run_report(%{content_changes: changes, renames: renames}) do
    Mix.shell().info([:yellow, "=== DRY RUN PREVIEW (No files were modified) ===\n"])

    Mix.shell().info([:cyan, "Files with content updates (#{length(changes)}):"])

    if changes == [] do
      Mix.shell().info("  (none)")
    else
      Enum.each(changes, fn path -> Mix.shell().info("  * #{path}") end)
    end

    Mix.shell().info(["\n", :cyan, "Files/Directories to rename (#{length(renames)}):"])

    if renames == [] do
      Mix.shell().info("  (none)")
    else
      Enum.each(renames, fn {old_path, new_path} ->
        Mix.shell().info("  * #{old_path} -> #{new_path}")
      end)
    end

    Mix.shell().info(["\n", :yellow, "Run again without --dry-run to apply these changes."])
  end

  defp print_usage_error do
    Mix.shell().error("""
    Did not provide required old and new project names.

    Usage:
      mix rename OldName NewName [--dry-run]
    """)

    {:error, :bad_params}
  end
end
