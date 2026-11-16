defmodule RenameProjectTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  setup do
    # Create an isolated temporary project directory for each test
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "rename_project_test_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp_dir)

    on_exit(fn ->
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  describe "derive_variants/1" do
    test "derives all casing conventions from PascalCase" do
      assert RenameProject.derive_variants("AshPhoenixStarter") == %{
               pascal: "AshPhoenixStarter",
               snake: "ash_phoenix_starter",
               kebab: "ash-phoenix-starter",
               upper_snake: "ASH_PHOENIX_STARTER",
               title: "Ash Phoenix Starter"
             }
    end

    test "derives all casing conventions from snake_case" do
      assert RenameProject.derive_variants("ash_phoenix_starter") == %{
               pascal: "AshPhoenixStarter",
               snake: "ash_phoenix_starter",
               kebab: "ash-phoenix-starter",
               upper_snake: "ASH_PHOENIX_STARTER",
               title: "Ash Phoenix Starter"
             }
    end

    test "derives all casing conventions from kebab-case" do
      assert RenameProject.derive_variants("ash-phoenix-starter") == %{
               pascal: "AshPhoenixStarter",
               snake: "ash_phoenix_starter",
               kebab: "ash-phoenix-starter",
               upper_snake: "ASH_PHOENIX_STARTER",
               title: "Ash Phoenix Starter"
             }
    end
  end

  describe "run/2" do
    test "renames files, nested directories, and all content variants", %{tmp_dir: tmp_dir} do
      create_sample_project(tmp_dir)

      assert :ok =
               RenameProject.run(
                 {"AshPhoenixStarter", "AcmePortal"},
                 starting_directory: tmp_dir
               )

      # Old paths should no longer exist
      refute File.exists?(Path.join(tmp_dir, "lib/ash_phoenix_starter.ex"))
      refute File.exists?(Path.join(tmp_dir, "lib/ash_phoenix_starter"))

      # New paths should exist
      new_app_file = Path.join(tmp_dir, "lib/acme_portal.ex")
      new_nested_file = Path.join(tmp_dir, "lib/acme_portal/accounts.ex")
      new_readme = Path.join(tmp_dir, "README.md")
      new_config = Path.join(tmp_dir, "config/runtime.exs")

      assert File.exists?(new_app_file)
      assert File.exists?(new_nested_file)

      # Verify PascalCase and snake_case inside Elixir files
      assert File.read!(new_app_file) == """
             defmodule AcmePortal do
               @otp_app :acme_portal
             end
             """

      assert File.read!(new_nested_file) == """
             defmodule AcmePortal.Accounts do
             end
             """

      # Verify Title Case and kebab-case inside Markdown
      assert File.read!(new_readme) == """
             # Acme Portal
             Deploy via `flyctl launch --name acme-portal`
             """

      # Verify UPPER_SNAKE_CASE inside config
      assert File.read!(new_config) == """
             import Config
             config :acme_portal, secret: System.get_env("ACME_PORTAL_SECRET")
             """
    end

    test "respects ignore_directories and ignore_files", %{tmp_dir: tmp_dir} do
      create_sample_project(tmp_dir)

      ignored_dir_file = Path.join(tmp_dir, "custom_ignored/ash_phoenix_starter.ex")
      ignored_file = Path.join(tmp_dir, "lib/keep_me.ex")

      File.mkdir_p!(Path.dirname(ignored_dir_file))
      File.write!(ignored_dir_file, "defmodule AshPhoenixStarter.Ignored do end")
      File.write!(ignored_file, "defmodule AshPhoenixStarter.KeepMe do end")

      assert :ok =
               RenameProject.run(
                 {"AshPhoenixStarter", "AcmePortal"},
                 starting_directory: tmp_dir,
                 ignore_directories: ["custom_ignored"],
                 ignore_files: ["keep_me.ex"]
               )

      assert File.read!(ignored_dir_file) == "defmodule AshPhoenixStarter.Ignored do end"
      assert File.read!(ignored_file) == "defmodule AshPhoenixStarter.KeepMe do end"
    end

    test "returns error on invalid arguments" do
      assert {:error, _msg} = RenameProject.run({:not_a_string, "AcmePortal"})
      assert {:error, _msg} = RenameProject.run("invalid_tuple")
    end
  end

  describe "run/2 with dry_run: true" do
    test "returns a report of pending changes without modifying disk", %{tmp_dir: tmp_dir} do
      create_sample_project(tmp_dir)

      assert {:ok, report} =
               RenameProject.run(
                 {"AshPhoenixStarter", "AcmePortal"},
                 starting_directory: tmp_dir,
                 dry_run: true
               )

      # Original files and directories must remain untouched
      assert File.exists?(Path.join(tmp_dir, "lib/ash_phoenix_starter.ex"))
      assert File.exists?(Path.join(tmp_dir, "lib/ash_phoenix_starter/accounts.ex"))
      refute File.exists?(Path.join(tmp_dir, "lib/acme_portal.ex"))

      assert File.read!(Path.join(tmp_dir, "README.md")) =~ "Ash Phoenix Starter"

      # Report should list the files that would change and paths that would rename
      assert Enum.any?(report.content_changes, &String.ends_with?(&1, "README.md"))
      assert Enum.any?(report.content_changes, &String.ends_with?(&1, "lib/ash_phoenix_starter.ex"))

      assert Enum.any?(report.renames, fn {old_path, new_path} ->
               String.ends_with?(old_path, "lib/ash_phoenix_starter.ex") and
                 String.ends_with?(new_path, "lib/acme_portal.ex")
             end)
    end
  end

  describe "Mix.Tasks.Rename" do
    setup do
      # Ensure Mix shell is set to Process so CaptureIO intercepts Mix.shell().info/error
      Mix.shell(Mix.Shell.Process)
      on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
      :ok
    end

    test "runs dry-run from CLI flags without touching files", %{tmp_dir: tmp_dir} do
      create_sample_project(tmp_dir)

      Mix.Tasks.Rename.run([
        "AshPhoenixStarter",
        "AcmePortal",
        "--dry-run",
        "--starting-directory",
        tmp_dir
      ])

      assert_received {:mix_shell, :info, [header]}
      assert IO.iodata_to_binary(header) =~ "DRY RUN PREVIEW"

      # Verify nothing changed on disk
      assert File.exists?(Path.join(tmp_dir, "lib/ash_phoenix_starter.ex"))
    end

    test "applies rename via Mix task", %{tmp_dir: tmp_dir} do
      create_sample_project(tmp_dir)

      Mix.Tasks.Rename.run([
        "AshPhoenixStarter",
        "AcmePortal",
        "--starting-directory",
        tmp_dir
      ])

      assert_received {:mix_shell, :info, [msg]}
      assert IO.iodata_to_binary(msg) =~ "Successfully renamed AshPhoenixStarter to AcmePortal!"
      assert File.exists?(Path.join(tmp_dir, "lib/acme_portal.ex"))
    end

    test "prints error on missing arguments" do
      assert {:error, :bad_params} = Mix.Tasks.Rename.run(["OnlyOneArg"])
      assert_received {:mix_shell, :error, [error_msg]}
      assert IO.iodata_to_binary(error_msg) =~ "Did not provide required old and new project names"
    end
  end

  # --- Helpers ---

  defp create_sample_project(root) do
    File.mkdir_p!(Path.join(root, "lib/ash_phoenix_starter"))
    File.mkdir_p!(Path.join(root, "config"))

    File.write!(Path.join(root, "lib/ash_phoenix_starter.ex"), """
    defmodule AshPhoenixStarter do
      @otp_app :ash_phoenix_starter
    end
    """)

    File.write!(Path.join(root, "lib/ash_phoenix_starter/accounts.ex"), """
    defmodule AshPhoenixStarter.Accounts do
    end
    """)

    File.write!(Path.join(root, "README.md"), """
    # Ash Phoenix Starter
    Deploy via `flyctl launch --name ash-phoenix-starter`
    """)

    File.write!(Path.join(root, "config/runtime.exs"), """
    import Config
    config :ash_phoenix_starter, secret: System.get_env("ASH_PHOENIX_STARTER_SECRET")
    """)
  end
end
