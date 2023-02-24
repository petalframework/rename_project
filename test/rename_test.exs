defmodule RenameTest do
  use ExUnit.Case

  @test_copy_dir "test_copy"
  @old_app_name "RenameProject"
  @old_app_otp "rename_project"
  @new_app_name "ToDoTwitterClone"
  @new_app_otp "to_do_twitter_clone"

  describe "defaults" do
    setup do
      on_exit(&cleanup/0)
      []
    end

    test "should properly rename app with default options" do
      create_copy_of_app()

      RenameProject.run(
        {@old_app_name, @new_app_name},
        {@old_app_otp, @new_app_otp},
        starting_directory: @test_copy_dir
      )

      mix_file = File.read!(@test_copy_dir <> "/mix.exs")
      assert mix_file |> String.contains?(@new_app_name)
      assert mix_file |> String.contains?(@new_app_otp)
      assert mix_file |> String.contains?(@old_app_name) == false
      main_module = File.read!(@test_copy_dir <> "/lib/" <> @new_app_otp <> ".ex")
      assert main_module |> String.contains?(@new_app_name)
      assert main_module |> String.contains?(@old_app_name) == false
      readme = File.read!(@test_copy_dir <> "/README.md")
      assert readme |> String.contains?(@new_app_otp)
      assert readme |> String.contains?(@old_app_name) == false
    end
  end

  test "should give proper error for invalid params" do
    assert RenameProject.run(
             {@old_app_name, @new_app_name},
             starting_directory: @test_copy_dir
           ) == {:error, "bad params"}
  end

  describe "custom options" do
    setup do
      on_exit(&cleanup/0)
      []
    end

    test "rename mix task works" do
      create_copy_of_app()

      Mix.Tasks.Rename.run([
        @old_app_name,
        @new_app_name,
        "--starting-directory",
        @test_copy_dir,
        "--ignore-directories",
        "lib"
      ])

      mix_file = File.read!(@test_copy_dir <> "/mix.exs")
      assert mix_file |> String.contains?(@new_app_name)
      assert mix_file |> String.contains?(@new_app_otp)
      assert mix_file |> String.contains?(@old_app_name) == false

      # We ignored the lib directory, so this file should not have been renamed
      {:error, reason} = File.read(@test_copy_dir <> "/lib/" <> @new_app_otp <> ".ex")
      assert reason == :enoent

      readme = File.read!(@test_copy_dir <> "/README.md")
      assert readme |> String.contains?(@new_app_otp)
      assert readme |> String.contains?(@old_app_name) == false
    end
  end

  test "rename mix task should give proper error for bad params" do
    {stdout, 0} = System.cmd("mix", ["rename", "hdjdj"])
    assert stdout =~ "mix rename OldName NewName"
  end

  def cleanup() do
    delete_copy_of_app()
  end

  defp create_copy_of_app do
    File.mkdir(@test_copy_dir)

    File.ls!()
    |> Enum.filter(&(File.dir?(&1) || Path.extname(&1) in ~w(.ex .exs .md)))
    |> Enum.reject(&(&1 in ignored_paths()))
    |> Enum.each(fn path ->
      System.cmd("cp", ["-r", path, @test_copy_dir])
    end)
  end

  defp delete_copy_of_app() do
    System.cmd("rm", ["-rf", @test_copy_dir])
  end

  defp ignored_paths do
    [
      "_build",
      "deps",
      @test_copy_dir,
      ".git",
      ".elixir_ls"
    ]
  end
end
