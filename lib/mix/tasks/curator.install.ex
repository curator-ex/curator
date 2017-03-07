defmodule Mix.Tasks.Curator.Install do
  @shortdoc "Install initial Curator templates"

  use Mix.Task

  @moduledoc """
  Install and configure Curator

      mix curator.install

  Optionally, you can provide a name for the users module

      mix curator.install User users

  The first argument is the module name followed by
  its plural name (used for schema).

  The generated resource will contain:

    * a schema in web/models
    * a migration file for the repository
    * a curator_hooks module in the lib/ot_app

  If you already have a model, the generated model can be skipped
  with `--no-model`.

  If you already have a migration, the generated migration can be skipped
  with `--no-migration`.

  If you already have a curator_hooks module, the generated hooks can be skipped
  with `--no-hooks`.
  """
  def run(args) do
    switches = [model: :boolean, migration: :boolean, hooks: :boolean]

    {opts, parsed, _} = OptionParser.parse(args, switches: switches)
    [singular, plural | attrs] = validate_args!(parsed)

    default_opts = Application.get_env(:curator, :generators, [])
    opts = Keyword.merge(default_opts, opts)

    attrs   = Mix.Phoenix.attrs(attrs)
    binding = Mix.Phoenix.inflect(singular)
    path    = binding[:path]
    otp_app = Mix.Phoenix.otp_app()
    binding = binding ++ [plural: plural,
                          attrs: attrs,
                          params: Mix.Phoenix.params(attrs)]

    files = hooks(opts[:hooks], otp_app)
      ++ model(opts[:model], path)
      ++ migration(opts[:migration], path)

    Mix.Phoenix.copy_from paths(), "priv/templates/curator.install", "", binding, files

    if opts[:migration] != false do
      Mix.shell.info """
      Remember to update your repository by running migrations:

          $ mix ecto.migrate
      """
    end
  end

  defp validate_args!([_, plural | _] = args) do
    cond do
      String.contains?(plural, ":") ->
        raise_with_help()
      plural != Phoenix.Naming.underscore(plural) ->
        Mix.raise "Expected the second argument, #{inspect plural}, to be all lowercase using snake_case convention"
      true ->
        args
    end
  end

  defp validate_args!(_) do
    ["User", "users"]
  end

  @spec raise_with_help() :: no_return()
  defp raise_with_help do
    Mix.raise """
    mix curator.install expects both singular and plural names

        mix curator.install User users
    """
  end

  defp paths do
    [".", :curator]
  end

  defp hooks(false, _otp_app), do: []
  defp hooks(_, otp_app) do
    [{:eex, "curator_hooks.ex",    "lib/#{otp_app}/curator_hooks.ex"}]
  end

  defp model(false, _path), do: []
  defp model(_, path) do
    [{:eex, "model.ex",           "web/models/#{path}.ex"},]
  end

  defp migration(false, _path), do: []
  defp migration(_, path) do
    [{:eex, "migration.exs",
      "priv/repo/migrations/#{timestamp()}_create_#{String.replace(path, "/", "_")}.exs"}]
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)
end
