defmodule Curator.UserSchema do
  defmacro __using__(opts \\ []) do
    # curator = Keyword.get(opts, :curator)

    quote do
      # use Curator.Config, unquote(opts)

      import unquote(__MODULE__), only: [curator_schema: 1]

      def curator_fields do
        [:password]
      end

      def curator_validation(changeset) do
        put_password_hash(changeset)
      end

      defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
        change(changeset, Comeonin.Bcrypt.add_hash(password))
      end

      defp put_password_hash(changeset), do: changeset

      # Config
      # def curator() do
      #   config(:curator)
      # end

      # def unauthenticated_routes(), do: apply(unquote(mod), :unauthenticated_routes, [])
      # def authenticated_routes(), do: apply(unquote(mod), :authenticated_routes, [])

      # def before_sign_in(user, opts \\ [])
      # def before_sign_in(user, opts), do: apply(unquote(mod), :before_sign_in, [user, opts])

      # def after_sign_in(conn, user, opts \\ [])
      # def after_sign_in(conn, user, opts), do: apply(unquote(mod), :after_sign_in, [conn, user, opts])

      # defoverridable unauthenticated_routes: 0,
      #                authenticated_routes: 0,
      #                before_sign_in: 2,
      #                after_sign_in: 3
    end
  end

  # defmacro curator_schema(curator) do
  #   curator_module = Macro.expand(curator, __CALLER__)
  #   modules = apply(curator_module, :config, [:modules, []])

  #   module_quotes = Enum.map(modules, &(apply(&1, :curator_schema, [])))
  #   |> Enum.filter(&(&1))

  #   quote do
  #     unquote(module_quotes)
  #   end
  # end

  defmacro curator_schema(curator) do
    curator = Macro.expand(curator, __CALLER__)
    modules = curator.config(:modules, [])
    module_quotes = Enum.map(modules, &(apply(&1, :curator_schema, [])))
    |> Enum.filter(&(&1))

    quote do
      unquote(module_quotes)
    end
  end

  # @type options :: Keyword.t()
  # # @type conditional_tuple :: {:ok, any} | {:error, any}

  # @callback before_sign_in(
  #             resource :: any,
  #             options :: options
  #           ) :: :ok | {:error, atom}

  # @callback after_sign_in(
  #             conn :: Plug.Conn.t(),
  #             resource :: any,
  #             options :: options
  #           ) :: Plug.Conn.t()

  # @callback unauthenticated_routes() :: nil
  # @callback authenticated_routes() :: nil

  # def before_sign_in(_user, _opts), do: :ok
  # def after_sign_in(conn, _user, _opts), do: conn

  # def unauthenticated_routes(), do: nil
  # def authenticated_routes(), do: nil
end
