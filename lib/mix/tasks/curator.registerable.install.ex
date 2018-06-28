defmodule Mix.Tasks.Curator.Registerable.Install do
  @shortdoc "Install Curator::Registerable"

  @moduledoc """
  Generates required Curator Registerable files.

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
    web_path = to_string(schema.web_path)

    [
      {:eex,     "registration_controller.ex",  Path.join([web_prefix, "controllers", web_path, "auth", "registration_controller.ex"])},
      {:eex,     "registerable.ex",             Path.join([web_prefix, web_path, "auth", "registerable.ex"])},
      {:eex,     "edit.html.eex",               Path.join([web_prefix, "templates", web_path, "auth", "registration", "edit.html.eex"])},
      {:eex,     "form.html.eex",               Path.join([web_prefix, "templates", web_path, "auth", "registration", "form.html.eex"])},
      {:eex,     "new.html.eex",                Path.join([web_prefix, "templates", web_path, "auth", "registration", "new.html.eex"])},
      {:eex,     "show.html.eex",               Path.join([web_prefix, "templates", web_path, "auth", "registration", "show.html.eex"])},
      {:eex,     "view.ex",                     Path.join([web_prefix, "views", web_path, "auth", "registration_view.ex"])},
    ]
  end

  @doc false
  def copy_new_files(%Context{} = context, paths, binding) do
    files = files_to_be_generated(context)
    Mix.Phoenix.copy_from paths, "priv/templates/curator.registerable.install", binding, files

    context
  end

  @doc false
  def print_shell_instructions(%Context{schema: schema, context_app: context_app} = context) do
    web_prefix = Mix.Phoenix.web_path(context_app)
    web_path = to_string(schema.web_path)

    Mix.shell.info """

    The Registerable module was created at: #{Path.join([web_prefix, web_path, "auth", "registerable.ex"])}

    You can configure it like so:

        use Curator.Registerable,
          otp_app: :#{Mix.Phoenix.otp_app()},
          curator: #{inspect context.web_module}.Auth.Curator

    Be sure to add it to Curator: #{Path.join([web_prefix, web_path, "auth", "curator.ex"])}

        use Curator,
          modules: [#{inspect context.web_module}.Auth.Registerable]

    """
  end
end
