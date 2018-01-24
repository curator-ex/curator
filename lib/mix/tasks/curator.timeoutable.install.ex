defmodule Mix.Tasks.Curator.Timeoutable.Install do
  @shortdoc "Install Curator"

  @moduledoc """
  Generates required Curator files.

      mix curator.install

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
      Mix.raise "mix curator.install can only be run inside an application directory"
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
      {:eex,     "timeoutable.ex",            Path.join([web_prefix, web_path, "auth", "timeoutable.ex"])},
    ]
  end

  @doc false
  def copy_new_files(%Context{} = context, paths, binding) do
    files = files_to_be_generated(context)
    Mix.Phoenix.copy_from paths, "priv/templates/curator.timeoutable.install", binding, files

    context
  end

  @doc false
  def print_shell_instructions(%Context{schema: schema, context_app: context_app} = context) do
    web_prefix = Mix.Phoenix.web_path(context_app)
    web_path = to_string(schema.web_path)

    Mix.shell.info """

    The Timeoutable module was created at: #{Path.join([web_prefix, web_path, "auth", "timeoutable.ex"])}

    You can configure it like so:

        use Curator.Timeoutable, otp_app: :#{Mix.Phoenix.otp_app()},
          timeout_in: 1800

    Be sure to add it to Curator: #{Path.join([web_prefix, web_path, "auth", "curator.ex"])}

        use Curator, otp_app: :#{Mix.Phoenix.otp_app()},
          modules: [#{inspect context.web_module}.Auth.Timeoutable]

        defmodule TimeStatsViewerWeb.Auth.Curator.UnauthenticatedPipeline do
          ...
          plug Curator.Timeoutable.Plug, timeoutable_module: #{inspect context.web_module}.Auth.Timeoutable
        end

        defmodule TimeStatsViewerWeb.Auth.Curator.AuthenticatedPipeline do
          ...
          plug Curator.Timeoutable.Plug, timeoutable_module: #{inspect context.web_module}.Auth.Timeoutable
        end

    NOTE: Don't forget to update your conn_case
    """
  end
end
