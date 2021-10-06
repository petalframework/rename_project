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
    |> Enum.each(fn path ->
      file_or_dir = Path.join([cwd, path])

      cond do
        is_valid_directory?(file_or_dir, options) ->
          rename_in_directory(names, otps, file_or_dir, options)
          true

        is_valid_file?(file_or_dir, options) ->
          file_or_dir
          |> File.read()
          |> case do
            {:ok, file} ->
              updated_file =
                file
                |> String.replace(old_name, new_name)
                |> String.replace(old_otp, new_otp)

              File.write(file_or_dir, updated_file)
              File.rename(file_or_dir, String.replace(file_or_dir, old_otp, new_otp))
              :ok

            _ ->
              :ok
          end

        true ->
          :ok
      end
    end)
  end

  defp is_valid_directory?(dir, options) do
    File.dir?(dir) and dir not in options[:exclude_directories]
  end

  defp is_valid_file?(file, options) do
    File.exists?(file) and
      (Path.basename(file) in options[:include_files] ||
         Path.basename(file) not in options[:exclude_files]) &&
      has_valid_extension?(file, options)
  end

  defp has_valid_extension?(file, options) do
    Path.extname(file) in options[:extensions]
  end
end
