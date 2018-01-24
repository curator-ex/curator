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
* [Registerable](https://github.com/curator-ex/curator_registerable): A Generator to support user registration.

## Installation

1. Add `curator` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:curator, "~> 0.2.0"}]
  end
  ```

  IMPORTANT: Update you applications to include:
  ```elixir
  [:timex, :timex_ecto, :tzdata]
  ```

2. Configure `config.exs`

  ```elixir
  config :curator, Curator,
    hooks_module: YourAppWeb.CuratorHooks,
    repo: YourApp.Repo,
    user_schema: YourApp.Auth.User,
    error_handler: YourAppWeb.Auth.ErrorHandler,
    context: YourApp.Auth
  ```

3. Run the install command
  ```elixir
    mix curator.install User users
  ```

  This will generate:
  1. A user migration (priv/repo/migrations/<timestamp>_create_user.exs)

  ```elixir
  defmodule <YourApp>.Repo.Migrations.CreateUser do
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

  2. A User Schema (web/models/user.ex)
  ```elixir
  defmodule <YourApp>.User do
    use <YourApp>.Web, :model

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

  3. An empty CuratorHooks Module (lib/<YourApp>/curator_hooks.ex)
  ```elixir
  defmodule <YourApp>.CuratorHooks do
    use <YourApp>.Web, :controller
    use Curator.Hooks
  end
  ```

  4. A session_helper (test/session_helper.ex)

  The session_helper should be added to your test/support/conn_case.ex

  ```elixir
  using do
    quote do
      ...

      import <YourApp>.SessionHelper
    end
  end
  ```

  5. An error_handler (web/controller/error_handler.ex)

  You'll want to customize the redirect paths. For instance, if you use a session

  ```elixir
  def unauthenticated(conn, %{reason: {:error, reason}}) do
    respond(conn, response_type(conn), 401, reason, session_path(conn, :new))
  end
  ```

  TODO: This file is kinda messy and is built as a Guardian.ErrorHandler (which has a few extra callbacks)

4. Add Plugs to the router

  ```elixir
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers

    plug Curator.Plug.LoadSession

    # Insert other Curator Plugs as necessary:
    # plug CuratorConfirmable.Plug

    plug Curator.Plug.EnsureResourceOrNoSession, handler: <YourApp>.ErrorHandler
  end

  pipeline :authenticated_browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers

    plug Curator.Plug.LoadSession

    # Insert other Curator Plugs as necessary:
    # plug CuratorConfirmable.Plug

    plug Curator.Plug.EnsureResourceAndSession, handler: <YourApp>.ErrorHandler
  end
  ```

  The browser session will still cause a log out if the user is invalid, but will allow a non-session through. This allows plugs that alter the conn to still fire (timeoutable), but also allows new visitors to get to you splash page. Your prtected resources should all be piped through authenticated_browser pipeline. The addition curator pages are designed to be run through the new browser pipeline (unless otherwise indicated).

5. Testing. That's important right?

  With a protected route:

  ```elixir
  scope "/", PhoenixCurator do
    pipe_through :authenticated_browser # Use the default browser stack

    get "/secret", PageController, :secret
  end
  ```

  You can use test authentication with the session_helper function sign_in_and_create_user:

  ```elixir
  defmodule PhoenixCurator.PageControllerTest do
    use PhoenixCurator.ConnCase

    alias Auth.User

    test "GET /", %{conn: conn} do
      conn = get conn, "/"
      assert html_response(conn, 200) =~ "Welcome to Phoenix!"
    end

    describe "testing authentication" do
      setup do
        conn = Phoenix.ConnTest.build_conn()
        |> conn_with_fetched_session

        {:ok, conn: conn}
      end

      test "visiting a secret page w/o a user", %{conn: conn} do
        conn = get conn, "/secret"

        assert Phoenix.Controller.get_flash(conn, :danger) == "Please Log In"

        # Customize this with as your redirect paths changes
        assert Phoenix.ConnTest.redirected_to(conn) == page_path(conn, :index)
      end

      test "sign_in_and_create_user", %{conn: conn} do
        {conn, _user} = sign_in_and_create_user(conn)

        conn = get conn, "/secret"

        # [Text Here](https://github.com/curator-ex/phoenix_curator/blob/master/web/templates/page/secret.html.eex)
        assert html_response(conn, 200) =~ "Sneaky, Sneaky, Sneaky..."
      end
    end
  end

  ```

6. Curate.

  Your authentication library is looking a bit spartan... Time to add to you collection.

  You probably want a session page, so try out [Database Authenticatable](https://github.com/curator-ex/curator_database_authenticatable). Without being able to sign up it won't be too helpful though... Maybe [Registerable](https://github.com/curator-ex/curator_registerable)?

7. Curations

  TODO: I'd love to support the idea of a curation, a collection of curator modules that can be installed with a single command. Unfortunatly, the generator code isn't advanced enough to edit existing files so it's a manual process for now.

8. Accessing current_user

in `web/web.ex`

```elixir
def view do
  quote do
    ...

    def current_user(conn) do
      Curator.PlugHelper.current_resource(conn)
    end
  end
end
```

Alternatively, you can see current_user in the contollers:

TODO: Document


## Curator Hooks Module

1. Want your_verification to run on every request? Check out the pattern in [Confirmable](https://github.com/curator-ex/curator_confirmable). It requires an update to your curator_hooks module:

```elixir
def before_sign_in(user) do
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

### Simple
TODO. This is not working yet.

The Simple Session Handler is a port of Guardian without JWT. Why? Some Blogs have raised objectsion that a JWT is too heavyweight (when you already have a session). Since we're making Curator modular, we made the session configurable as well. We owe a huge debt to the Guardian team for making such a great pattern to follow.

Configure `config.exs`

```elixir
config :curator, Curator,
  hooks_module: AuthApp.CuratorHooks,
  repo: AuthApp.Repo,
  user_schema: AuthApp.User
```

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
  serializer: Curator.UserSerializer

config :curator, Curator,
  hooks_module: AuthApp.CuratorHooks,
  repo: AuthApp.Repo,
  user_schema: AuthApp.User
```

## Debt
Thanks go out to the [Phoenix Team](https://github.com/phoenixframework/phoenix), the original rails project [Devise](https://github.com/plataformatec/devise), and the other elixir authentication solutions:

[Guardian](https://github.com/ueberauth/guardian)
[Coherence](https://github.com/smpallen99/coherence)
[Sentinel](https://github.com/britton-jb/sentinel)
[Openmaize](https://github.com/riverrun/openmaize)

Any decent ideas I credit to them, I was just acting as the curator.
