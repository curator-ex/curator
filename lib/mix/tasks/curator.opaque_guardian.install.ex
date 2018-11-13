defmodule Mix.Tasks.Curator.OpaqueGuardian.Install do
@shortdoc "Install Curator (for Opaque Guardian)"

  @moduledoc """
  Generates Opaque Guardian files.

      mix curator.opaque_guardian.install

  NOTE: This was copied and adapted from: mix phx.gen.context
  """

  use Mix.Task

  alias Mix.Phoenix.Context
  alias Mix.Tasks.Phx.Gen

  @doc false
  def run(args) do
    args = ["Auth", "Token", "auth_tokens", "token:string:unique", "description:string", "claims:map", "user_id:references:users", "typ:string", "exp:integer"] ++ args

    if Mix.Project.umbrella? do
      Mix.raise "mix curator.opaque_guardian.install can only be run inside an application directory"
    end

    {context, schema} = Gen.Context.build(args)

    schema = Map.put(schema, :migration?, false)
    context = Map.put(context, :schema, schema)

    binding = [context: context, schema: schema]

    paths = Mix.Phoenix.generator_paths()
    context
    |> Gen.Context.copy_new_files(paths, binding)

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
    db_prefix = Mix.Phoenix.context_app_path(context_app, "")
    # web_prefix = Mix.Phoenix.web_path(context_app)
    # web_path = to_string(schema.web_path)

    [
      {:force_eex,  "schema.ex",            schema.file},
      {:eex,     "migration.exs",           Path.join([db_prefix, "priv/repo/migrations/#{timestamp()}_create_auth_tokens.exs"])},
    ]
  end

  defp guardian_file_path(%Context{schema: schema, context_app: context_app}) do
    web_prefix = Mix.Phoenix.web_path(context_app)
    web_path = to_string(schema.web_path)

    Path.join([web_prefix, web_path, "auth", "guardian.ex"])
  end

  @doc false
  def copy_new_files(%Context{} = context, paths, binding) do
    files = files_to_be_generated(context)
    copy_from paths, "priv/templates/curator.opaque_guardian.install", binding, files
    inject_guardian_module(context, paths, binding)
    inject_schema_access(context, paths, binding)

    context
  end

  defp inject_guardian_module(context, paths, binding) do
    paths
    |> Mix.Phoenix.eval_from("priv/templates/curator.opaque_guardian.install/opaque_guardian.ex", binding)
    |> inject_eex_after_final_end(guardian_file_path(context), binding)
  end

  defp inject_schema_access(%Context{file: file} = context, paths, binding) do
    unless Context.pre_existing?(context) do
      raise "No context to inject into"
    end

    paths
    |> Mix.Phoenix.eval_from("priv/templates/curator.opaque_guardian.install/schema_access.ex", binding)
    |> inject_eex_before_final_end(file, binding)
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
  def print_shell_instructions(%Context{} = context) do
    Mix.shell.info """

    Add the new association to the user schema:

        has_many :tokens, #{inspect context.module}.Token

    """

    if context.generate?, do: Gen.Context.print_shell_instructions(context)
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end
  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)
end
