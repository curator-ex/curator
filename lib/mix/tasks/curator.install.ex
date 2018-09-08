defmodule Mix.Tasks.Curator.Install do
  @shortdoc "Install Curator"

  @moduledoc """
  Generates required Curator files.

      mix curator.install

  NOTE: This was copied and adapted from: mix phx.gen.context
  """

  use Mix.Task

  alias Mix.Phoenix.Context
  alias Mix.Tasks.Phx.Gen

  # @switches [binary_id: :boolean, table: :string, web: :string,
  #            schema: :boolean, context: :boolean, context_app: :string]

  # @default_opts [schema: true, context: true]

  @doc false
  def run(args) do
    args = ["Auth", "User", "users", "email:unique"] ++ args

    if Mix.Project.umbrella? do
      Mix.raise "mix curator.install can only be run inside an application directory"
    end

    Gen.Context.run(args)

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
      {:eex,     "curator.ex",                Path.join([web_prefix, web_path, "auth", "curator.ex"])},
      {:eex,     "email.ex",                  Path.join([web_prefix, web_path, "auth", "email.ex"])},
      {:eex,     "email/layout.html.eex",     Path.join([web_prefix, "templates", web_path, "auth", "layout", "email.html.eex"])},
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
    inject_schema_access(context, paths, binding)

    context
  end

  defp inject_schema_access(%Context{file: file} = context, paths, binding) do
    unless Context.pre_existing?(context) do
      raise "No context to inject into"
    end

    paths
    |> Mix.Phoenix.eval_from("priv/templates/curator.install/schema_access.ex", binding)
    |> inject_eex_before_final_end(file, binding)
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

  defp write_file(content, file) do
    File.write!(file, content)
  end

  @doc false
  def print_shell_instructions(%Context{context_app: context_app} = context) do
    web_prefix = Mix.Phoenix.web_path(context_app)

    Mix.shell.info """

    Add curator to your router #{Mix.Phoenix.web_path(context_app)}/router.ex:

        require Curator.Router

        pipeline :browser do
          ...
          plug #{inspect context.web_module}.Auth.Curator.UnauthenticatedPipeline
        end

        pipeline :authenticated_browser do
          ... (copy the code from browser)
          plug #{inspect context.web_module}.Auth.Curator.AuthenticatedPipeline
        end

        scope "/", #{inspect context.web_module} do
          pipe_through :browser

          ...

          Curator.Router.mount_unauthenticated_routes(#{inspect context.web_module}.Auth.Curator)
        end

        scope "/", #{inspect context.web_module} do
          pipe_through :authenticated_browser

          ...

          Curator.Router.mount_authenticated_routes(#{inspect context.web_module}.Auth.Curator)
        end

    Add the view_helper to your Web module: #{Path.join([web_prefix, "#{web_prefix}.ex"])}

        def view do
          quote do
            ...

            import #{inspect context.web_module}.Auth.CuratorHelper
          end
        end

    Configure Guardian: config/config.exs

        config :#{Mix.Phoenix.otp_app()}, #{inspect context.web_module}.Auth.Guardian,
          issuer: "#{Mix.Phoenix.otp_app()}",
          secret_key: "Secret key. You can use `mix guardian.gen.secret` to get one"

    And configure Guardian for production: config/prod.exs

        config :#{Mix.Phoenix.otp_app()}, #{inspect context.web_module}.Auth.Guardian,
          issuer: "#{Mix.Phoenix.otp_app()}",
          allowed_algos: ["HS512"],
          ttl: { 1, :days },
          verify_issuer: true,
          secret_key: {#{inspect context.web_module}.Auth.Guardian, :fetch_secret_key, []}
    """

    if context.generate?, do: Gen.Context.print_shell_instructions(context)
  end
end
