defmodule Mix.Tasks.Curator.Recoverable.Install do
  @shortdoc "Install` Curator"

  @moduledoc """
  Generates required Curator Recoverable files.

      mix curator.recoverable.install

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

    if Mix.Project.umbrella?() do
      Mix.raise("mix curator.recoverable.install can only be run inside an application directory")
    end

    # Gen.Context.run(args)

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
    # db_prefix = Mix.Phoenix.context_app_path(context_app, "")
    web_prefix = Mix.Phoenix.web_path(context_app)
    # test_prefix = Mix.Phoenix.web_test_path(context_app)
    web_path = to_string(schema.web_path)

    [
      {:eex, "recoverable.ex", Path.join([web_prefix, web_path, "auth", "recoverable.ex"])},
      {:eex, "new.html.eex",
       Path.join([web_prefix, "templates", web_path, "auth", "recoverable", "new.html.eex"])},
      {:eex, "edit.html.eex",
       Path.join([web_prefix, "templates", web_path, "auth", "recoverable", "edit.html.eex"])},
      {:eex, "recoverable_controller.ex",
       Path.join([web_prefix, "controllers", web_path, "auth", "recoverable_controller.ex"])},
      {:eex, "view.ex",
       Path.join([web_prefix, "views", web_path, "auth", "recoverable_view.ex"])},
      {:eex, "email/recoverable.html.eex",
       Path.join([web_prefix, "templates", web_path, "auth", "email", "recoverable.html.eex"])}
    ]
  end

  @doc false
  def copy_new_files(%Context{} = context, paths, binding) do
    files = files_to_be_generated(context)
    Mix.Phoenix.copy_from(paths, "priv/templates/curator.recoverable.install", binding, files)
    inject_email_module(context, paths, binding)

    context
  end

  defp email_file_path(%Context{schema: schema, context_app: context_app}) do
    web_prefix = Mix.Phoenix.web_path(context_app)
    web_path = to_string(schema.web_path)

    Path.join([web_prefix, web_path, "auth", "email.ex"])
  end

  defp inject_email_module(context, paths, binding) do
    paths
    |> Mix.Phoenix.eval_from("priv/templates/curator.recoverable.install/email.ex", binding)
    |> inject_eex_before_final_end(email_file_path(context), binding)
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

    The Recoverable module was created at: #{
      Path.join([web_prefix, web_path, "auth", "recoverable.ex"])
    }

    You can configure it like so:

        use Curator.Recoverable,
          otp_app: :#{Mix.Phoenix.otp_app()},
          curator: #{inspect(context.web_module)}.Auth.Curator

    Be sure to add it to Curator: #{Path.join([web_prefix, web_path, "auth", "curator.ex"])}

        use Curator,
          modules: [#{inspect(context.web_module)}.Auth.Recoverable]

    """)
  end
end
