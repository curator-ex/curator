defmodule Mix.Tasks.Curator.Install do
  @shortdoc "Install Curator"

  @moduledoc """
  Generates a context with functions around an Ecto schema.

      mix phx.gen.context Accounts User users name:string age:integer

  The first argument is the context module followed by the schema module
  and its plural name (used as the schema table name).

  The context is an Elixir module that serves as an API boundary for
  the given resource. A context often holds many related resources.
  Therefore, if the context already exists, it will be augmented with
  functions for the given resource. Note a resource may also be split
  over distinct contexts (such as Accounts.User and Payments.User).

  The schema is responsible for mapping the database fields into an
  Elixir struct.

  Overall, this generator will add the following files to lib/your_app:

    * a context module in accounts/accounts.ex, serving as the API boundary
    * a schema in accounts/user.ex, with a `users` table

  A migration file for the repository and test files for the context
  will also be generated.

  ## Generating without a schema

  In some cases, you may wish to boostrap the context module and
  tests, but leave internal implementation of the context and schema
  to yourself. Use the `--no-schema` flags to accomplish this.

  ## table

  By default, the table name for the migration and schema will be
  the plural name provided for the resource. To customize this value,
  a `--table` option may be provided. For example:

      mix phx.gen.context Accounts User users --table cms_users

  ## binary_id

  Generated migration can use `binary_id` for schema's primary key
  and its references with option `--binary-id`.

  ## Default options

  This generator uses default options provided in the `:generators`
  configuration of your application. These are the defaults:

      config :your_app, :generators,
        migration: true,
        binary_id: false,
        sample_binary_id: "11111111-1111-1111-1111-111111111111"

  You can override those options per invocation by providing corresponding
  switches, e.g. `--no-binary-id` to use normal ids despite the default
  configuration or `--migration` to force generation of the migration.

  Read the documentation for `phx.gen.schema` for more information on
  attributes.
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
      Mix.raise "mix phx.gen.context can only be run inside an application directory"
    end

    Gen.Context.run(args)

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
      {:eex,     "curator_hooks.ex",          Path.join([web_prefix, "controllers", web_path, "auth", "curator_hooks.ex"])},
      # {:eex,     "view.ex",                 Path.join([web_prefix, "views", web_path, "#{schema.singular}_view.ex"])},
      # {:eex,     "controller_test.exs",     Path.join([test_prefix, "controllers", web_path, "#{schema.singular}_controller_test.exs"])},
      # {:new_eex, "changeset_view.ex",       Path.join([web_prefix, "views/changeset_view.ex"])},
      {:eex,     "error_handler.ex",          Path.join([web_prefix, "controllers", web_path, "auth", "error_handler.ex"])},
      {:eex,     "ueberauth_controller.ex",   Path.join([web_prefix, "controllers", web_path, "auth", "ueberauth_controller.ex"])},
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

          resources "/#{schema.plural}", #{inspect schema.alias}Controller, except: [:new, :edit]
      """
    end
    if context.generate?, do: Gen.Context.print_shell_instructions(context)
  end
end
