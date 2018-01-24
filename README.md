# Curator

An Authentication Framework for Phoenix.

Curator is meant to mimic [Devise](https://github.com/plataformatec/devise), as such it provides [several modules](#curator-modules) to accomplish authentication and various aspects of user lifecycle mangement. It's build with a modular architecture that differs from existing Elixir Authentication solutions. Each curator module can be combined to handle various authentication scenarios, passing coordination through a [curator module](#curator-module). Under the hood, this uses [Guardian](https://github.com/ueberauth/guardian) for session management.

For an example, see the [PhoenixCurator Application](https://github.com/curator-ex/phoenix_curator)

## Curator Modules

* [Ueberauth](#ueberauth): Ueberauth Integration.
* [Timeoutable](#timeoutable): Session Timeout (after configurable inactivity).

(TODO)

* [Registerable](#registerable): A Generator to support user registration.
* [Database Authenticatable](#database_authenticatable): Compare a password to a hashed password to support password based sign-in. Also provide a generator for creating a session page.
* [Confirmable](#confirmable): Account email verification.
* [Recoverable](#recoverable): Reset the User Password.
* [Lockable](#lockable): Lock Account after configurbale count of invalid sign-ins.
* [Approvable](#approvable): Require an approval step before user sign-in.

## Installation

1. Add `curator` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:curator, "~> 0.2.0"}]
  end
  ```

2. Run the install command
  ```elixir
  mix curator.install
  ```

  This will generate:

  1. A User context, migration, and schema (in the Ecto application if an umbrella)

    1. A user migration (priv/repo/migrations/<timestamp>_create_users.exs)

    2. A user schema (<my_app>/lib/<my_app>/auth/user.ex)

    3. A user context (<my_app>/lib/<my_app>/auth/auth.ex)

  2. An empty Curator module (<my_app_web>/lib/<my_app_web>/auth/curator.ex)

  3. A Guardian Configuration

    1. A Guardian module (<my_app_web>/lib/<my_app_web>/auth/guardian.ex)

    2. An error handler  (<my_app_web>/lib/<my_app_web>/controllers/auth/error_handler.ex)

  4. A view helper (<my_app_web>/lib/<my_app_web>/views/auth/curator_helper.ex)

  5. A Session Controller

    1. A controller (<my_app_web>/lib/<my_app_web>/controllers/auth/session_controller.ex)

    2. A view helper (<my_app_web>/lib/<my_app_web>/views/auth/curator_helper.ex)

    3. A new template (<my_app_web>/lib/<my_app_web>/templates/auth/session/new.html.eex)

  6. Test Helper (TODO)

3. The generators aren't perfect (TODO), so finish the installation

  1. Update your router (<my_app_web>/lib/<my_app_web>/router.ex)

    ```elixir
    require Curator.Router

    pipeline :browser do
      ...
      plug <MyWebApp>.Auth.Curator.UnauthenticatedPipeline
    end

    pipeline :authenticated_browser do
      plug <MyWebApp>.Auth.Curator.AuthenticatedPipeline
    end

    scope "/", <MyWebApp> do
      pipe_through :browser

      ...

      Curator.Router.mount_unauthenticated_routes(<MyWebApp>.Auth.Curator)
    end

    scope "/", <MyWebApp> do
      pipe_through [:browser, :authenticated_browser]

      ...

      Curator.Router.mount_authenticated_routes(<MyWebApp>.Auth.Curator)
    end
    ```

  2. Add the view_helper to your web module (<my_app_web>/lib/<my_app_web>.ex)

    ```elixir
    def view do
      quote do
        ...

        import <MyAppWeb>.Auth.CuratorHelper
      end
    end
    ```

    This allows you to call `current_user(conn)` in your templates

  3. [Configure Guardian](https://github.com/ueberauth/guardian#installation) in `config.exs`

    ```elixir
    config :<my_app_web>, <MyAppWeb>.Guardian,
      issuer: "<my_app_web>",
      secret_key: "Secret key. You can use `mix guardian.gen.secret` to get one"
    ```

4. Add a signout link to your layout
  ```elixir
  <%= if current_user(@conn) do %>
    <%= link "Sign Out", to: session_path(@conn, :delete), method: :delete %>
  <% end %>
  ```

5. Testing

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

5. Curate.

  Your authentication library is looking a bit spartan... Time to add to you collection.

  You probably want a session page, so try out [Database Authenticatable](https://github.com/curator-ex/curator_database_authenticatable). Without being able to sign up it won't be too helpful though... Maybe [Registerable](https://github.com/curator-ex/curator_registerable)?

7. Curations

  TODO: I'd love to support the idea of a curation, a collection of curator modules that can be installed with a single command. Unfortunatly, the generator code isn't advanced enough to edit existing files so it's a manual process for now.

## Module Documentation

### Ueberauth

#### Description
Ueberauth Integration

#### Installation

1. Run the install command
  ```elixir
  mix curator.ueberauth.install
  ```

2. Add to curator modules (<my_app_web>/lib/<my_app_web>/auth/curator.ex)
  ```elixir
  use Curator, otp_app: :my_app_web,
    modules: [
      MyAppWeb.Auth.Ueberauth,
    ]
  ```

3. Install Ueberauth and the desired [strategies](https://github.com/ueberauth/ueberauth#configuring-providers). For example, to add google oauth:

  1. Update mix.exs
    ```elixir
    defp deps do
      [
        {:ueberauth, "~> 0.4"},
        {:ueberauth_google, "~> 0.7"},
      ]
    end
    ```

  2. Update config.exs
    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        google: {Ueberauth.Strategy.Google, []}
      ]

    config :ueberauth, Ueberauth.Strategy.Google.OAuth,
      client_id: System.get_env("GOOGLE_CLIENT_ID"),
      client_secret: System.get_env("GOOGLE_CLIENT_SECRET")
    ```

  3. Put some links to the providers (<my_app_web>/lib/<my_app_web>/templates/auth/session/new.html.eex)
    ```elixir
    <%= link "Google", to: ueberauth_path(@conn, :request, "google"), class: "btn btn-default" %>
    ```


### Timeoutable

#### Description
Session Timeout (after configurable inactivity)

#### Installation

1. Run the install command
  ```elixir
  mix curator.timeoutable.install
  ```

2. Add to curator modules (<my_app_web>/lib/<my_app_web>/auth/curator.ex)
  ```elixir
  use Curator, otp_app: :my_app_web,
    modules: [
      MyAppWeb.Auth.Timeoutable,
    ]
  ```

3. Add to the curator plugs
  ```elixir
  defmodule <MyAppWeb>.Auth.Curator.UnauthenticatedPipeline do
    ...
    plug Curator.Timeoutable.Plug, timeoutable_module: <MyAppWeb>.Auth.Timeoutable
  end

  defmodule <MyAppWeb>.Auth.Curator.AuthenticatedPipeline do
    ...
    plug Curator.Timeoutable.Plug, timeoutable_module: <MyAppWeb>.Auth.Timeoutable
  end
  ```

4. (optional) Configure Timeoutable (<my_app_web>/lib/<my_app_web>/auth/timeoutable.ex)

  ```elixir
  use Curator.Timeoutable, otp_app: :<my_app_web>,
    timeout_in: 1800
  ```

### Registerable

### Database Authenticatable

### Confirmable

### Recoverable

### Lockable

### Approvable

# Extending Curator

## Design Pattern

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

# Debt
Thanks go out to the [Phoenix Team](https://github.com/phoenixframework/phoenix), the original rails gem [Devise](https://github.com/plataformatec/devise), [Guardian](https://github.com/ueberauth/guardian), and the other elixir authentication solutions:

[Coherence](https://github.com/smpallen99/coherence)
[Sentinel](https://github.com/britton-jb/sentinel)
[Openmaize](https://github.com/riverrun/openmaize)

Any decent ideas I credit to them, I was just acting as the curator.
