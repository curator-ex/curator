defmodule Mix.Tasks.Curator.Api.Install do
  @shortdoc "Install Curator (for API)"

  @moduledoc """
  Generates required Curator API files.

      mix curator.api.install

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
    args = ["Auth", "Token", "auth_tokens", "token:string:unique", "description:string", "claims:map", "user_id:references:users", "typ:string", "exp:bigint:index"] ++ args

    if Mix.Project.umbrella? do
      Mix.raise "mix curator.api.install can only be run inside an application directory"
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
    web_path = to_string(schema.web_path)

    [
      {:eex,        "api_error_handler.ex", Path.join([web_prefix, "controllers", web_path, "auth", "api_error_handler.ex"])},
      {:force_eex,  "schema.ex",            schema.file}
    ]
  end

  defp curator_file_path(%Context{schema: schema, context_app: context_app}) do
    web_prefix = Mix.Phoenix.web_path(context_app)
    web_path = to_string(schema.web_path)

    Path.join([web_prefix, web_path, "auth", "curator.ex"])
  end

  defp guardian_file_path(%Context{schema: schema, context_app: context_app}) do
    web_prefix = Mix.Phoenix.web_path(context_app)
    web_path = to_string(schema.web_path)

    Path.join([web_prefix, web_path, "auth", "guardian.ex"])
  end

  @doc false
  def copy_new_files(%Context{} = context, paths, binding) do
    files = files_to_be_generated(context)
    copy_from paths, "priv/templates/curator.api.install", binding, files
    inject_curator_module(context, paths, binding)
    inject_guardian_module(context, paths, binding)

    context
  end

  defp inject_curator_module(context, paths, binding) do
    paths
    |> Mix.Phoenix.eval_from("priv/templates/curator.api.install/api_pipeline.ex", binding)
    |> inject_eex_after_final_end(curator_file_path(context), binding)
  end

  defp inject_guardian_module(context, paths, binding) do
    paths
    |> Mix.Phoenix.eval_from("priv/templates/curator.api.install/opaque_guardian.ex", binding)
    |> inject_eex_after_final_end(guardian_file_path(context), binding)
  end

  defp write_file(content, file) do
    File.write!(file, content)
  end

  defp inject_eex_after_final_end(content_to_inject, file_path, binding) do
    file = File.read!(file_path)

    if String.contains?(file, content_to_inject) do
      :ok
    else
      Mix.shell.info([:green, "* injecting ", :reset, Path.relative_to_cwd(file_path)])

      file
      |> String.trim_trailing()
      |> EEx.eval_string(binding)
      |> Kernel.<>(content_to_inject)
      |> write_file(file_path)
    end
  end

  def copy_from(apps, source_dir, binding, mapping) when is_list(mapping) do
    roots = Enum.map(apps, &to_app_source(&1, source_dir))

    for {format, source_file_path, target} <- mapping do
      source =
        Enum.find_value(roots, fn root ->
          source = Path.join(root, source_file_path)
          if File.exists?(source), do: source
        end) || raise "could not find #{source_file_path} in any of the sources"

      case format do
        :text -> Mix.Generator.create_file(target, File.read!(source))
        :eex  -> Mix.Generator.create_file(target, EEx.eval_file(source, binding))
        :new_eex ->
          if File.exists?(target) do
            :ok
          else
            Mix.Generator.create_file(target, EEx.eval_file(source, binding))
          end
        :force_eex -> Mix.Generator.create_file(target, EEx.eval_file(source, binding), force: true)
      end
    end
  end

  defp to_app_source(path, source_dir) when is_binary(path),
    do: Path.join(path, source_dir)
  defp to_app_source(app, source_dir) when is_atom(app),
    do: Application.app_dir(app, source_dir)

  @doc false
  def print_shell_instructions(%Context{context_app: context_app} = context) do
    Mix.shell.info """

    Add curator to your router #{Mix.Phoenix.web_path(context_app)}/router.ex:

        require Curator.Router

        pipeline :api do
          ...
          plug #{inspect context.web_module}.Auth.Curator.ApiPipeline
        end

        scope "/api", #{inspect context.web_module} do
          pipe_through :api

          ...
        end

    Add the new association to the user schema:

        has_many :tokens, #{inspect context.module}.Auth.Token

    """

    if context.generate?, do: Gen.Context.print_shell_instructions(context)
  end
end
