defmodule Rename do
  @moduledoc """
  The single module that does all the renaming
  Talk about pressure
  At least there are tests
  Well there's "a" test
  But it does like one thing
  So it's fine
  If you're mad about it, submit a PR.
  """

  @default_extensions ~w(
    .eex
    .env
    .ex
    .exs
    .md
    .yml
  )

  @default_include_files ~w(
    .dockerignore
    Dockerfile
    entrypoint.sh
    Makefile
    mix.exs
  )

  @default_exclude_directories ~w(
    .elixir_ls
    _build
    deps
    assets
  )

  @default_starting_directory "."

  @default_exclude_files []

  @doc """
  The public function you use to rename your app.
  Call looks like: run({"OldName", "NewName"}, {"old_otp", "new_otp"}, options)
  """

  def run({old_otp, new_otp}, options) when is_list(options) do
    run({camelise(old_otp), camelise(new_otp)}, {old_otp, new_otp}, options)
  end

  def run(names, otps, options \\ [])

  def run({_old_name, _new_name} = names, {_old_otp, _new_otp} = otps, options) do
    options =
      options
      |> Enum.reduce(defaults(), fn
        {k, v}, acc when is_list(v) ->
          new_value =
            acc
            |> Keyword.get(k)
            |> then(&(&1 ++ v))

          Keyword.put(acc, k, new_value)

        {k, v}, acc ->
          Keyword.put(acc, k, v)
      end)

    names
    |> rename_in_directory(
      otps,
      options[:starting_directory],
      options
    )
  end

  def run(_names, _otp, _options), do: {:error, "bad params"}

  defp defaults do
    [
      exclude_directories: @default_exclude_directories,
      exclude_files: @default_exclude_files,
      extensions: @default_extensions,
      starting_directory: @default_starting_directory,
      include_files: @default_include_files
    ]
  end

  defp rename_in_directory(names = {old_name, new_name}, otps = {old_otp, new_otp}, cwd, options) do
    cwd
    |> File.ls!()
    |> Enum.reject(&excluded_directory?(&1, options))
    |> Enum.each(fn file_or_dir ->
      path = Path.join([cwd, file_or_dir])

      cond do
        File.dir?(path) ->
          rename_in_directory(names, otps, path, options)
          true

        is_valid_file?(path, options) ->
          path
          |> File.read()
          |> case do
            {:ok, file} ->
              updated_file =
                file
                |> String.replace(old_name, new_name)
                |> String.replace(old_otp, new_otp)
                |> String.replace(dasherised(old_otp), dasherised(new_otp))

              File.write(path, updated_file)
              true

            _ ->
              false
          end

        true ->
          false
      end
      |> case do
        true ->
          rename_file(path, old_otp, new_otp)

        _ ->
          :ok
      end
    end)
  end

  defp rename_file(path, old_otp, new_otp) do
    File.rename(path, String.replace(path, old_otp, new_otp))
  end

  defp excluded_directory?(dir, options) do
    File.dir?(dir) and dir in options[:exclude_directories]
  end

  defp is_valid_file?(file, options) do
    File.exists?(file) and
      (Path.basename(file) in options[:include_files] ||
         Path.basename(file) not in options[:exclude_files]) &&
      has_valid_extension?(file, options)
  end

  defp has_valid_extension?(file, options) do
    file
    |> Path.extname()
    |> case do
      "" ->
        true

      ext ->
        ext in options[:extensions]
    end
  end

  defp dasherised(name), do: String.replace(name, "_", "-")

  defp camelise(name) do
    name
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join()
  end
end
