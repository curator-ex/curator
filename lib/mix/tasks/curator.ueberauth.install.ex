defmodule Mix.Tasks.Curator.Ueberauth.Install do
  @shortdoc "Install Curator::Ueberauth"

  @moduledoc """
  Generates required Curator Ueberauth files.

      mix curator.ueberauth.install

  NOTE: This was copied and adapted from: mix phx.gen.context
  """

  use Mix.Task

  alias Mix.Phoenix.Context
  alias Mix.Tasks.Phx.Gen

  # @switches [binary_id: :boolean, table: :string, web: :string,
  #            schema: :boolean, context: :boolean, context_app: :string]
  #
  # @default_opts [schema: true, context: true]

  @doc false
  def run(args) do
    args = ["Auth", "User", "users", "email:unique"] ++ args

    if Mix.Project.umbrella?() do
      Mix.raise("mix curator.ueberauth.install can only be run inside an application directory")
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
    web_path = to_string(schema.web_path)

    [
      {:eex, "ueberauth_controller.ex",
       Path.join([web_prefix, "controllers", web_path, "auth", "ueberauth_controller.ex"])},
      {:eex, "ueberauth.ex", Path.join([web_prefix, web_path, "auth", "ueberauth.ex"])}
    ]
  end

  @doc false
  def copy_new_files(%Context{} = context, paths, binding) do
    files = files_to_be_generated(context)
    Mix.Phoenix.copy_from(paths, "priv/templates/curator.ueberauth.install", binding, files)
    inject_schema_access(context, paths, binding)
    inject_tests(context, paths, binding)

    context
  end

  defp inject_schema_access(%Context{file: file} = context, paths, binding) do
    unless Context.pre_existing?(context) do
      raise "No context to inject into"
    end

    paths
    |> Mix.Phoenix.eval_from("priv/templates/curator.ueberauth.install/schema_access.ex", binding)
    |> inject_eex_before_final_end(file, binding)
  end

  defp inject_tests(%Context{test_file: test_file} = context, paths, binding) do
    unless Context.pre_existing_tests?(context) do
      raise "No context tests to inject into"
    end

    paths
    |> Mix.Phoenix.eval_from("priv/templates/curator.ueberauth.install/test_cases.exs", binding)
    |> inject_eex_before_final_end(test_file, binding)
  end

  defp inject_eex_before_final_end(content_to_inject, file_path, binding) do
    file = File.read!(file_path)

    if String.contains?(file, content_to_inject) do
      :ok
    else
      Mix.shell().info([:green, "* injecting ", :reset, Path.relative_to_cwd(file_path)])

      file
      |> String.trim_trailing()
      |> String.trim_trailing("end")
      |> EEx.eval_string(binding)
      |> Kernel.<>(content_to_inject)
      |> Kernel.<>("end\n")
      |> write_file(file_path)
    end
  end

  defp write_file(content, file) do
    File.write!(file, content)
  end

  @doc false
  def print_shell_instructions(%Context{schema: schema, context_app: context_app} = context) do
    web_prefix = Mix.Phoenix.web_path(context_app)
    web_path = to_string(schema.web_path)

    Mix.shell().info("""

    Setup Ueberauth:

        config :ueberauth, Ueberauth,
          providers: [
            google: {Ueberauth.Strategy.Google, []}
          ]

        config :ueberauth, Ueberauth.Strategy.Google.OAuth,
          client_id: System.get_env("GOOGLE_CLIENT_ID"),
          client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

    More info: https://github.com/ueberauth/ueberauth#setup

    The Ueberauth module was created at: #{
      Path.join([web_prefix, web_path, "auth", "ueberauth.ex"])
    }

    Be sure to add it to Curator: #{Path.join([web_prefix, web_path, "auth", "curator.ex"])}

        use Curator,
          modules: [#{inspect(context.web_module)}.Auth.Ueberauth]

    """)
  end
end
