defmodule Mix.Tasks.Curator.Registerable.Install do
  @shortdoc "Install Curator::Registerable"

  @moduledoc """
  Generates required Curator files.

      mix curator.registerable.install

  NOTE: This was copied and adapted from: mix phx.gen.context
  """

  use Mix.Task

  alias Mix.Phoenix.{Context, Schema}
  alias Mix.Tasks.Phx.Gen

  @switches [binary_id: :boolean, table: :string, web: :string,
             schema: :boolean, context: :boolean, context_app: :string]

  @default_opts [schema: true, context: true]

  @doc false
  def run(args) do
    args = ["Auth", "User", "users", "email:unique"] ++ args

    if Mix.Project.umbrella? do
      Mix.raise "mix curator.registerable.install can only be run inside an application directory"
    end

    {context, schema} = Gen.Context.build(args)

    binding = [context: context, schema: schema]
    paths = generator_paths()

    context
    |> copy_new_files(paths, binding)
    |> print_shell_instructions()
  end

  def generator_paths do
    [".", :curator]
  end

  @doc false
  def files_to_be_generated(%Context{schema: schema, context_app: context_app}) do
    web_prefix = Mix.Phoenix.web_path(context_app)
    # test_prefix = Mix.Phoenix.web_test_path(context_app)
    web_path = to_string(schema.web_path)

    [
      {:eex,     "registration_controller.ex",   Path.join([web_prefix, "controllers", web_path, "auth", "registration_controller.ex"])},
      {:eex,     "registerable.ex",               Path.join([web_prefix, web_path, "auth", "registerable.ex"])},
    ]
  end

  @doc false
  def copy_new_files(%Context{} = context, paths, binding) do
    files = files_to_be_generated(context)
    Mix.Phoenix.copy_from paths, "priv/templates/curator.registerable.install", binding, files
    inject_schema_access(context, paths, binding)
    inject_tests(context, paths, binding)

    context
  end

  defp inject_schema_access(%Context{file: file} = context, paths, binding) do
    unless Context.pre_existing?(context) do
      Mix.Generator.create_file(file, Mix.Phoenix.eval_from(paths, "priv/templates/curator.registerable.install/context.ex", binding))
    end

    paths
    |> Mix.Phoenix.eval_from("priv/templates/curator.registerable.install/schema_access.ex", binding)
    |> inject_eex_before_final_end(file, binding)
  end

  defp write_file(content, file) do
    File.write!(file, content)
  end

  defp inject_tests(%Context{test_file: test_file} = context, paths, binding) do
    unless Context.pre_existing_tests?(context) do
      Mix.Generator.create_file(test_file, Mix.Phoenix.eval_from(paths, "priv/templates/curator.registerable.install/context_test.exs", binding))
    end

    paths
    |> Mix.Phoenix.eval_from("priv/templates/curator.registerable.install/test_cases.exs", binding)
    |> inject_eex_before_final_end(test_file, binding)
  end

  defp inject_eex_before_final_end(content_to_inject, file_path, binding) do
    file = File.read!(file_path)

    if String.contains?(file, content_to_inject) do
      :ok
    else
      Mix.shell.info([:green, "* injecting ", :reset, Path.relative_to_cwd(file_path)])

      file
      |> String.trim_trailing()
      |> String.trim_trailing("end")
      |> EEx.eval_string(binding)
      |> Kernel.<>(content_to_inject)
      |> Kernel.<>("end\n")
      |> write_file(file_path)
    end
  end

  @doc false
  def print_shell_instructions(%Context{schema: schema, context_app: context_app} = context) do
    web_prefix = Mix.Phoenix.web_path(context_app)
    web_path = to_string(schema.web_path)

    Mix.shell.info """

    Setup Registerable:

        config :registerable, Registerable,
          providers: [
            google: {Registerable.Strategy.Google, []}
          ]

        config :registerable, Registerable.Strategy.Google.OAuth,
          client_id: System.get_env("GOOGLE_CLIENT_ID"),
          client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

    More info: https://github.com/registerable/registerable#setup

    The Registerable module was created at: #{Path.join([web_prefix, web_path, "auth", "registerable.ex"])}

    Be sure to add it to Curator: #{Path.join([web_prefix, web_path, "auth", "curator.ex"])}

        use Curator, otp_app: :#{Mix.Phoenix.otp_app()},
          modules: [#{inspect context.web_module}.Auth.Registerable]

    """
  end
end
