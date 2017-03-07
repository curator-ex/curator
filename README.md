# Curator

An Authentication Framework for Phoenix.

Curator is meant to mimic [Devise](https://github.com/plataformatec/devise), as such it provides [several modules](#curator-modules) to accomplish authentication and various aspects of user lifecycle mangement (see modules below). It's build with a module architecture that differs from existing Elixir Authentication solutions. Each curator module is a separate Hex package which can be combined to handle various authentication scenarios, passing coordination though a [CuratorHooks module](#curator-hooks-module).

TODO: Curator uses [Guardian](https://github.com/ueberauth/guardian) for session management. However, a JWT approach may be inappropriate for some applications, and so API and Browser [session management](#session-management) is configurable.

For an example, see the [PhoenixCurator Application](https://github.com/curator-ex/phoenix_curator)

## Curator Modules

* [Timeoutable](https://github.com/curator-ex/curator_timeoutable): Session Timeout (after configurable inactivity).
* [Recoverable](https://github.com/curator-ex/curator_recoverable): Reset the User Password.
* [Lockable](https://github.com/curator-ex/curator_lockable): Lock Account after configurbale count of invalid sign-ins.
* [Database Authenticatable](https://github.com/curator-ex/curator_database_authenticatable): Compare a password to a hashed password to support password based sign-in. Also provide a generator for creating a session page.
* [Confirmable](https://github.com/curator-ex/curator_confirmable): Account email verification.
* [Approvable](https://github.com/curator-ex/curator_approvable): Require an approval step before user sign-in.

## Installation

  1. Add `curator` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:curator, "~> 0.1.0"}]
    end
    ```

  2. Configure `config.exs`

    ```elixir
    config :curator, Curator,
      hooks_module: AuthApp.CuratorHooks,
      repo: AuthApp.Repo,
      user_schema: AuthApp.User
    ```

  3. Run the install command
    This will generate a user migration, a user module, and curator_hooks module.

    ```elixir
      mix curator.install User users
    ```

    ```elixir
    defmodule PhoenixCurator.Repo.Migrations.CreateUser do
      use Ecto.Migration

      def change do
        create table(:users) do
          add :email, :string

          timestamps()
        end

        create unique_index(:users, [:email])
      end
    end
    ```

    ```elixir
    defmodule PhoenixCurator.User do
      use PhoenixCurator.Web, :model

      # Use Curator Modules (as needed).
      # use CuratorDatabaseAuthenticatable.Schema

      schema "users" do
        field :email, :string

        # Add Curator Module fields (as needed).
        # curator_database_authenticatable_schema
      end

      def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:email])
        |> validate_required([:email])
        |> validate_format(:email, ~r/@/)
        |> unique_constraint(:email)
      end
    end
    ```

    ```elixir
    defmodule PhoenixCurator.CuratorHooks do
      use PhoenixCurator.Web, :controller
      use Curator.Hooks
    end
    ```

  4. Curate.

    Your authentication library is looking a bit spartan... Time to add to you collection.

    You probably want a session page, so try out [Database Authenticatable](https://github.com/curator-ex/curator_database_authenticatable).


## Curator Hooks Module

    1. Want your_verification to run on every request? Check out the pattern in [Confirmable](https://github.com/curator-ex/curator_confirmable). It requires an update to your curator_hooks module:

    ```elixir
    def before_sign_in(user, type) do
      with :ok <- your_verification(user) do
        :ok
      end
    end
    ```

    where your_verification returns :ok or {:error, 'message'}

    And add a new Plug (in between your LoadResource and EnsureResource Plugs)

    ```elixir
    def call(conn, opts) do
      key = Map.get(opts, :key, Curator.default_key)

      case Curator.PlugHelper.current_resource(conn, key) do
        nil -> conn
        {:error, _error} -> conn
        current_resource ->
          case your_verification(current_resource) do
            :ok -> conn
            {:error, error} -> Curator.PlugHelper.clear_current_resource_with_error(conn, error, key)
          end
      end
    end
    ```

    2. An example of utilizing Curator.Hooks.after_sign_in can be seen in the [Timeoutable](https://github.com/curator-ex/curator_timeoutable) Module.

    3. An example of utilizing Curator.Hooks.after_failed_sign_in can be seen in the [Lockable](https://github.com/curator-ex/curator_lockable) Module.

    4. Need More? There's a Curator.Hooks.after_extension callback which can be pattern matched for additional functionality, as seen in the [Approvable](https://github.com/curator-ex/curator_approvable) Module.

## Session Management

### CuratorSession
  TODO

### Guardian

1. `mix.exs`

  ```elixir
  def deps do
    [{:guardian, "~> 0.14"}]
  end
  ```

2. `config.exs`

  ```elixir
  config :guardian, Guardian,
    issuer: "AuthApp",
    ttl: { 1, :days },
    allowed_drift: 2000,
    verify_issuer: true,
    secret_key: <guardian secret key>,
    serializer: AuthApp.GuardianSerializer
  ```

3. TODO...

## Debt
  Thanks go out to the [Phoenix Team](https://github.com/phoenixframework/phoenix), the original rails project [Devise](https://github.com/plataformatec/devise), and the other elixir authentication solutions:

  [Guardian](https://github.com/ueberauth/guardian)
  [Coherence](https://github.com/smpallen99/coherence)
  [Sentinel](https://github.com/britton-jb/sentinel)
  [Openmaize](https://github.com/riverrun/openmaize)

  Any decent ideas I credit to them, I was just acting as the curator.
