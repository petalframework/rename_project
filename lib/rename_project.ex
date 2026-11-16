defmodule RenameProject do
  @moduledoc """
  Renames an Elixir/Phoenix project across all casing styles:
  PascalCase, snake_case, kebab-case, UPPER_SNAKE_CASE, and Title Case.
  Supports `dry_run: true` to preview changes safely before touching disk.
  """

  @default_extensions ~w(.ex .exs .eex .heex .leex .md .json .yml .yaml .toml .env .sh)
  @default_ignore_directories ~w(.elixir_ls .vscode .git _build deps assets node_modules)
  @default_ignore_files []
  @default_include_files ~w(mix.exs Dockerfile .formatter.exs)
  @default_starting_directory "."

  @type name_pair :: {String.t(), String.t()}
  @type option ::
          {:dry_run, boolean()}
          | {:ignore_directories, [String.t()]}
          | {:ignore_files, [String.t()]}
          | {:include_extensions, [String.t()]}
          | {:include_files, [String.t()]}
          | {:starting_directory, String.t()}

  @type dry_run_report :: %{
          content_changes: [String.t()],
          renames: [{String.t(), String.t()}]
        }

  @doc """
  Renames the project using a single `{old_name, new_name}` tuple.
  Accepts PascalCase, snake_case, or kebab-case and automatically converts
  all variants (`AshPhoenixStarter`, `ash_phoenix_starter`, `ash-phoenix-starter`, etc.).

  Pass `dry_run: true` to preview all changes without modifying disk.

  ## Examples

      # Preview changes
      {:ok, report} = RenameProject.run({"AshPhoenixStarter", "AcmePortal"}, dry_run: true)

      # Apply changes
      :ok = RenameProject.run({"AshPhoenixStarter", "AcmePortal"})
  """
  @spec run(name_pair(), [option()]) :: :ok | {:ok, dry_run_report()} | {:error, String.t()}
  def run(names, options \\ [])

  def run({old_name, new_name}, options)
      when is_binary(old_name) and is_binary(new_name) and is_list(options) do
    config = build_config(options)
    old_variants = derive_variants(old_name)
    new_variants = derive_variants(new_name)

    replacements = build_replacements(old_variants, new_variants)
    otp_pair = {old_variants.snake, new_variants.snake}

    execute(config.starting_directory, replacements, otp_pair, config)
  end

  def run(_names, _options), do: {:error, "Invalid parameters. Expected {old_name, new_name}."}

  @doc """
  Backwards-compatible function for explicit `{names, otps}` tuples.
  """
  @spec run(name_pair(), name_pair(), [option()]) ::
          :ok | {:ok, dry_run_report()} | {:error, String.t()}
  def run({old_name, new_name}, {old_otp, new_otp}, options)
      when is_binary(old_name) and is_binary(new_name) and
             is_binary(old_otp) and is_binary(new_otp) and is_list(options) do
    config = build_config(options)

    replacements =
      [
        {old_name, new_name},
        {old_otp, new_otp},
        {String.replace(old_otp, "_", "-"), String.replace(new_otp, "_", "-")},
        {String.upcase(old_otp), String.upcase(new_otp)}
      ]
      |> clean_replacements()

    execute(config.starting_directory, replacements, {old_otp, new_otp}, config)
  end

  @doc """
  Normalizes any name format (`"AshPhoenixStarter"`, `"ash_phoenix_starter"`, or `"ash-phoenix-starter"`)
  into a map of all project naming conventions.
  """
  @spec derive_variants(String.t()) :: %{
          pascal: String.t(),
          snake: String.t(),
          kebab: String.t(),
          upper_snake: String.t(),
          title: String.t()
        }
  def derive_variants(name) when is_binary(name) do
    snake =
      name
      |> String.trim()
      |> String.replace("-", "_")
      |> Macro.underscore()

    %{
      pascal: Macro.camelize(snake),
      snake: snake,
      kebab: String.replace(snake, "_", "-"),
      upper_snake: String.upcase(snake),
      title: snake |> String.split("_") |> Enum.map_join(" ", &String.capitalize/1)
    }
  end

  # --- Private Helpers ---

  defp execute(dir, replacements, otp_pair, config) do
    initial_acc = %{content_changes: [], renames: []}
    report = process_directory(dir, replacements, otp_pair, config, initial_acc)

    if config.dry_run do
      {:ok,
       %{
         content_changes: Enum.reverse(report.content_changes),
         renames: Enum.reverse(report.renames)
       }}
    else
      :ok
    end
  end

  defp build_replacements(old_v, new_v) do
    [
      {old_v.pascal, new_v.pascal},
      {old_v.snake, new_v.snake},
      {old_v.kebab, new_v.kebab},
      {old_v.upper_snake, new_v.upper_snake},
      {old_v.title, new_v.title}
    ]
    |> clean_replacements()
  end

  defp clean_replacements(pairs) do
    pairs
    |> Enum.reject(fn {old, new} -> old == new or old == "" end)
    |> Enum.uniq()
    |> Enum.sort_by(fn {old, _new} -> String.length(old) end, :desc)
  end

  defp build_config(options) do
    defaults = %{
      dry_run: false,
      ignore_directories: @default_ignore_directories,
      ignore_files: @default_ignore_files,
      include_extensions: @default_extensions,
      include_files: @default_include_files,
      starting_directory: @default_starting_directory
    }

    Enum.reduce(options, defaults, fn
      {key, val}, acc when is_list(val) and is_map_key(acc, key) ->
        Map.update!(acc, key, &Enum.uniq(&1 ++ val))

      {key, val}, acc when is_map_key(acc, key) ->
        Map.put(acc, key, val)

      _unknown, acc ->
        acc
    end)
  end

  defp process_directory(dir, replacements, otp_pair, config, acc) do
    dir
    |> File.ls!()
    |> Enum.sort()
    |> Enum.reduce(acc, fn entry, current_acc ->
      full_path = Path.join(dir, entry)

      cond do
        File.dir?(full_path) ->
          if entry in config.ignore_directories do
            current_acc
          else
            current_acc
            |> then(&process_directory(full_path, replacements, otp_pair, config, &1))
            |> maybe_rename_path(full_path, otp_pair, config)
          end

        valid_file?(full_path, entry, config) ->
          current_acc
          |> update_file_contents(full_path, replacements, config)
          |> maybe_rename_path(full_path, otp_pair, config)

        true ->
          current_acc
      end
    end)
  end

  defp valid_file?(full_path, basename, config) do
    cond do
      not File.regular?(full_path) -> false
      basename in config.include_files -> true
      basename in config.ignore_files -> false
      true -> valid_extension?(basename, config.include_extensions)
    end
  end

  defp valid_extension?(basename, allowed_extensions) do
    case Path.extname(basename) do
      "" -> true
      ext -> ext in allowed_extensions
    end
  end

  defp update_file_contents(acc, path, replacements, config) do
    with {:ok, content} <- File.read(path) do
      updated_content =
        Enum.reduce(replacements, content, fn {old, new}, text ->
          String.replace(text, old, new)
        end)

      if updated_content != content do
        unless config.dry_run do
          File.write!(path, updated_content)
        end

        Map.update!(acc, :content_changes, &[path | &1])
      else
        acc
      end
    else
      _ -> acc
    end
  end

  defp maybe_rename_path(acc, path, {old_otp, new_otp}, config) do
    dirname = Path.dirname(path)
    basename = Path.basename(path)

    if String.contains?(basename, old_otp) do
      new_basename = String.replace(basename, old_otp, new_otp)
      new_path = Path.join(dirname, new_basename)

      unless config.dry_run do
        File.rename!(path, new_path)
      end

      Map.update!(acc, :renames, &[{path, new_path} | &1])
    else
      acc
    end
  end
end
