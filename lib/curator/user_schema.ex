# defmodule Curator.UserSchema do
#   defmacro __using__(opts \\ []) do
#     quote do
#       use Curator.Config, unquote(opts)

#       import unquote(__MODULE__), only: [curator_schema: 1]

#       def curator_fields do
#         Curator.UserSchema.curator_fields(__MODULE__)
#       end

#       def curator_validation(changeset) do
#         Curator.UserSchema.curator_validation(__MODULE__, changeset)
#       end
#     end
#   end

#   # TODO: I could not access the __MODULE__.config(curator)
#   # I'd rather not pass the same variable into the `use` and `curator_schema` calls
#   defmacro curator_schema(curator) do
#     curator = Macro.expand(curator, __CALLER__)
#     modules = curator.config(:modules, [])
#     module_quotes = Enum.map(modules, &(apply(&1, :curator_schema, [])))
#     |> Enum.filter(&(&1))

#     quote do
#       unquote(module_quotes)
#     end
#   end

#   def curator_fields(mod) do
#     curator = mod.config(:curator)
#     modules = curator.config(:modules, [])

#     Enum.reduce(modules, [], fn(module, acc) -> acc ++ module.curator_fields() end)
#   end

#   def curator_validation(mod, changeset) do
#     curator = mod.config(:curator)
#     modules = curator.config(:modules, [])

#     Enum.reduce(modules, changeset, fn(module, acc) -> module.curator_validation(acc) end)
#   end
# end
