defmodule Mix.Tasks.Curator.Install do
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

    # Gen.Context.run(args)

    {context, schema} = Gen.Context.build(args)
    # Gen.Context.prompt_for_code_injection(context)

    binding = [context: context, schema: schema]
    paths = generator_paths()

    # prompt_for_conflicts(context)

    context
    |> copy_new_files(paths, binding)
    |> print_shell_instructions()
  end

  def generator_paths do
    [".", :curator]
  end

  # defp prompt_for_conflicts(context) do
  #   context
  #   |> files_to_be_generated()
  #   |> Kernel.++(context_files(context))
  #   |> Mix.Phoenix.prompt_for_conflicts()
  # end
  # defp context_files(%Context{generate?: true} = context) do
  #   Gen.Context.files_to_be_generated(context)
  # end
  # defp context_files(%Context{generate?: false}) do
  #   []
  # end

  @doc false
  def files_to_be_generated(%Context{schema: schema, context_app: context_app}) do
    web_prefix = Mix.Phoenix.web_path(context_app)
    # test_prefix = Mix.Phoenix.web_test_path(context_app)
    web_path = to_string(schema.web_path)

    [
      {:eex,     "curator.ex",                Path.join([web_prefix, web_path, "auth", "curator.ex"])},
      {:eex,     "curator_helper.ex",         Path.join([web_prefix, "views", web_path, "auth", "curator_helper.ex"])},
      {:eex,     "error_handler.ex",          Path.join([web_prefix, "controllers", web_path, "auth", "error_handler.ex"])},
      {:eex,     "view.ex",                   Path.join([web_prefix, "views", web_path, "auth", "session_view.ex"])},
      {:eex,     "new.html.eex",              Path.join([web_prefix, "templates", web_path, "auth", "session", "new.html.eex"])},
      {:eex,     "session_controller.ex",     Path.join([web_prefix, "controllers", web_path, "auth", "session_controller.ex"])},
      {:eex,     "guardian.ex",               Path.join([web_prefix, web_path, "auth", "guardian.ex"])},
    ]
  end

  @doc false
  def copy_new_files(%Context{} = context, paths, binding) do
    files = files_to_be_generated(context)
    Mix.Phoenix.copy_from paths, "priv/templates/curator.install", binding, files
    # if context.generate?, do: Gen.Context.copy_new_files(context, paths, binding)

    context
  end

  @doc false
  def print_shell_instructions(%Context{schema: schema, context_app: ctx_app} = context) do
    if schema.web_namespace do
      Mix.shell.info """

      Add the resource to your #{schema.web_namespace} :api scope in #{Mix.Phoenix.web_path(ctx_app)}/router.ex:

          scope "/#{schema.web_path}", #{inspect Module.concat(context.web_module, schema.web_namespace)} do
            pipe_through :api
            ...
            resources "/#{schema.plural}", #{inspect schema.alias}Controller
          end
      """
    else
      Mix.shell.info """

      Add the resource to your :api scope in #{Mix.Phoenix.web_path(ctx_app)}/router.ex:

          resources "/#{schema.plural}", #{inspect schema.alias}Controller

      Configure Guardian:

          config :#{Mix.Phoenix.otp_app()}, #{inspect context.web_module}.Auth.Guardian,
            issuer: "#{Mix.Phoenix.otp_app()}",
            secret_key: "Secret key. You can use `mix guardian.gen.secret` to get one"

      """
    end
    if context.generate?, do: Gen.Context.print_shell_instructions(context)
  end
end
