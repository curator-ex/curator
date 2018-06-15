# Curator

An Authentication Framework for Phoenix.

Curator is meant to mimic [Devise](https://github.com/plataformatec/devise), as such it provides [several modules](#curator-modules) to accomplish authentication and various aspects of user lifecycle mangement. It's build with a modular architecture that differs from existing Elixir Authentication solutions. Each curator module can be combined to handle various authentication scenarios, passing coordination through a curator module](#curator-module). Under the hood, this uses [Guardian](https://github.com/ueberauth/guardian) for session management.

For an example, see the [PhoenixCurator Application](https://github.com/curator-ex/phoenix_curator)

## Curator Modules

* [Ueberauth](#ueberauth): Ueberauth Integration.
* [Timeoutable](#timeoutable): Session Timeout (after configurable inactivity).
* [API](#api): API login (with an opaque token).

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
      [{:curator, "~> 0.2.5"}]
    end
    ```

2. Run the install command

    ```
    mix curator.install
    ```

    This will generate:

    1. A User context, migration, and schema (in the Ecto application if an umbrella)

        * A user migration (`priv/repo/migrations/<timestamp>_create_users.exs`)
        * A user schema (`<my_app>/lib/<my_app>/auth/user.ex`)
        * A user context (`<my_app>/lib/<my_app>/auth/auth.ex`)

    2. An empty Curator module (`<my_app_web>/lib/<my_app_web>/auth/curator.ex`)

    3. A Guardian Configuration

        * A Guardian module (`<my_app_web>/lib/<my_app_web>/auth/guardian.ex`)
        * An error handler  (`<my_app_web>/lib/<my_app_web>/controllers/auth/error_handler.ex`)

    4. A view helper (`<my_app_web>/lib/<my_app_web>/views/auth/curator_helper.ex`)

    5. A Session Controller

        * controller (`<my_app_web>/lib/<my_app_web>/controllers/auth/session_controller.ex`)
        * view helper (`<my_app_web>/lib/<my_app_web>/views/auth/curator_helper.ex`)
        * new template (`<my_app_web>/lib/<my_app_web>/templates/auth/session/new.html.eex`). Note: this is just a placeholder that you'll want to update when you decide on a sign-in strategy.

3. The generators aren't perfect (TODO), so finish the installation

    1. Update your router (`<my_app_web>/lib/<my_app_web>/router.ex`)

        ```elixir
        require Curator.Router

        pipeline :browser do
          ...
          plug <MyWebApp>.Auth.Curator.UnauthenticatedPipeline
        end

        pipeline :authenticated_browser do
          ... (copy the code from browser)
          plug <MyWebApp>.Auth.Curator.AuthenticatedPipeline
        end

        scope "/", <MyWebApp> do
          pipe_through :browser

          ...
          Insert your unprotected routes here
          ...

          Curator.Router.mount_unauthenticated_routes(<MyWebApp>.Auth.Curator)
        end

        scope "/", <MyWebApp> do
          pipe_through :authenticated_browser

          ...
          Insert your unprotected routes here
          ...

          Curator.Router.mount_authenticated_routes(<MyWebApp>.Auth.Curator)
        end
        ```

    2. Add the view_helper to your web module (`<my_app_web>/lib/<my_app_web>.ex`)

        ```elixir
        def view do
          quote do
            ...

            import <MyAppWeb>.Auth.CuratorHelper
          end
        end
        ```

        This allows you to call `current_user(@conn)` in your templates

    3. [Configure Guardian](https://github.com/ueberauth/guardian#installation) in `config.exs`

        ```elixir
        config :<my_app_web>, <MyAppWeb>.Auth.Guardian,
          issuer: "<my_app_web>",
          secret_key: "Secret key. You can use `mix guardian.gen.secret` to get one"
        ```

        and `prod.exs`

        ```elixir
        config :<my_app_web>, <MyAppWeb>.Auth.Guardian,
          issuer: "<my_app_web>",
          allowed_algos: ["HS512"],
          ttl: { 1, :days },
          verify_issuer: true,
          secret_key: {<MyAppWeb>.Auth.Guardian, :fetch_secret_key, []}
        ```

        (NOTE: the sameple prod.exs is one way to keep the `secret_key` out of source code. If you use an alternative technique the `fetch_secret_key` method can be removed from `<MyAppWeb>.Auth.Guardian`)

    4. Add to your Auth Context (`<my_app>/lib/<my_app>/auth/auth.ex`)

        ```elixir
        def get_user(id) do
          case Repo.get(User, id) do
            nil -> {:error, :no_resource_found}
            record -> {:ok, record}
          end
        end
        ```

4. Add a signout link to your layout

    ```elixir
    <%= if current_user(@conn) do %>
      <%= link "Sign Out", to: session_path(@conn, :delete), method: :delete %>
    <% end %>
    ```

5. Testing

    Update `conn_case.ex`:

    ```elixir
    setup tags do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(<MyApp>.Repo)
      unless tags[:async] do
        Ecto.Adapters.SQL.Sandbox.mode(<MyApp>.Repo, {:shared, self()})
      end

      # Create w/ ExMachina (or your preferred method)
      # Note: As you add additional modules, make sure this user is valid for them too.
      auth_user = <MyApp>.Factory.insert(:auth_user)

      {:ok, token, claims} = <MyAppWeb>.Auth.Guardian.encode_and_sign(auth_user)

      conn = Phoenix.ConnTest.build_conn()

      auth_conn = conn
      |> Plug.Test.init_test_session(%{
        guardian_default_token: token,
        guardian_default_timeoutable: Curator.Time.timestamp(),
      })

      {:ok, unauth_conn: conn, auth_user: auth_user, conn: auth_conn}
    end
    ```

    Note: This uses `conn` as an authenticated connection, so existing tests won't need to be updated.

    To test, I created some special routes:

    ```elixir
    scope "/", <MyAppWeb> do
      pipe_through :browser

      if Mix.env == :test do
        get "/insecure", PageController, :insecure
      end

      Curator.Router.mount_unauthenticated_routes(<MyAppWeb>.Auth.Curator)
    end

    scope "/", <MyAppWeb> do
      pipe_through :authenticated_browser

      if Mix.env == :test do
        get "/secure", PageController, :secure
      end

      Curator.Router.mount_authenticated_routes(<MyAppWeb>.Auth.Curator)
    end
    ```

    Update the `page_controller.ex`:

    ```elixir
    defmodule <MyAppWeb>.PageController do
      use <MyAppWeb>, :controller

      def secure(conn, _params) do
        text conn, "!!!SECURE!!!"
      end

      def insecure(conn, _params) do
        text conn, "INSECURE"
      end
    end
    ```

    And wrote tests in `page_controller_test.exs`:

    ```
    defmodule <MyAppWeb>.PageControllerTest do
      use <MyAppWeb>.ConnCase

      test "GET /secure (Unauthenticated)", %{unauth_conn: conn} do
        conn = get conn, "/secure"
        assert redirected_to(conn) == session_path(conn, :new)
        assert get_flash(conn, :error) == "Please Sign In"
      end

      test "GET /secure (Authenticated)", %{conn: conn} do
        conn = get conn, "/secure"
        assert text_response(conn, 200) == "!!!SECURE!!!"
      end

      test "GET /secure (Authenticated - User Delete)", %{conn: conn, auth_user: user} do
        <MyApp>.Auth.delete_user(user)
        conn = get conn, "/secure"
        assert redirected_to(conn) == session_path(conn, :new)
        assert get_flash(conn, :error) == "Please Sign In"
      end

      test "GET /insecure (Unauthenticated)", %{unauth_conn: conn} do
        conn = get conn, "/insecure"
        assert text_response(conn, 200) == "INSECURE"
      end

      test "GET /insecure (Authenticated)", %{conn: conn} do
        conn = get conn, "/insecure"
        assert text_response(conn, 200) == "INSECURE"
      end

      test "GET /insecure (Authenticated - User Delete)", %{conn: conn, auth_user: user} do
        <MyApp>.Auth.delete_user(user)
        conn = get conn, "/insecure"
        assert redirected_to(conn) == session_path(conn, :new)
        assert get_flash(conn, :error) == "Please Sign In"
      end
    end
    ```

    These examples can be extended as additional modules are integrated (ex. using Confirmable with a user that hasn't been confirmed).

6. Curate.

    Your authentication library is looking a bit spartan... Time to add to you collection.

    Currently only an oauth workflow is supported, so start with [Ueberauth](#ueberauth)

## Module Documentation

### Ueberauth

#### Description
Ueberauth Integration

#### Installation

1. Run the install command

    ```
    mix curator.ueberauth.install
    ```

2. Add to the curator modules (`<my_app_web>/lib/<my_app_web>/auth/curator.ex`)

    ```elixir
    use Curator, otp_app: :my_app_web,
      modules: [
        <MyAppWeb>.Auth.Ueberauth,
      ]
    ```

3. Install Ueberauth and the desired [strategies](https://github.com/ueberauth/ueberauth#configuring-providers). For example, to add google oauth:

    1. Update `mix.exs`

        ```elixir
        defp deps do
          [
            {:ueberauth, "~> 0.4"},
            {:ueberauth_google, "~> 0.7"},
          ]
        end
        ```

        NOTE: If you're using an umbrella app you'll also need to add ueberauth to your ecto applications `mix.exs`.

    2. Update `config.exs`

        ```elixir
        config :ueberauth, Ueberauth,
          providers: [
            google: {Ueberauth.Strategy.Google, []}
          ]

        config :ueberauth, Ueberauth.Strategy.Google.OAuth,
          client_id: System.get_env("GOOGLE_CLIENT_ID"),
          client_secret: System.get_env("GOOGLE_CLIENT_SECRET")
        ```

    3. Put some links to the providers (`<my_app_web>/lib/<my_app_web>/templates/auth/session/new.html.eex`)

        ```elixir
        <%= link "Google", to: ueberauth_path(@conn, :request, "google"), class: "btn btn-default" %>
        ```

### Timeoutable

#### Description
Session Timeout (after configurable inactivity)

#### Installation

1. Run the install command

    ```
    mix curator.timeoutable.install
    ```

2. Add to the curator modules (`<my_app_web>/lib/<my_app_web>/auth/curator.ex`)

    ```elixir
    use Curator, otp_app: :<my_app_web>,
      modules: [
       <MyAppWeb>.Auth.Timeoutable,
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

4. (optional) Configure Timeoutable (`<my_app_web>/lib/<my_app_web>/auth/timeoutable.ex`)

    ```elixir
    use Curator.Timeoutable, otp_app: :<my_app_web>,
      timeout_in: 1800
    ```

5. Update tests (`<my_app_web>/test/support/conn_case.ex`)

    ```elixir
    auth_conn = conn
    |> Plug.Test.init_test_session(%{
      guardian_default_token: token,
      guardian_default_timeoutable: Curator.Time.timestamp(),
    })
    ```

    This session key usually is set as part of the after_sign_in extension.

6. (optional) Update the ErrorHandler (`<my_app_web>/lib/<my_app_web>/controllers/auth/error_handler.ex`)

    ```elixir
    defp translate_error({:timeoutable, :timeout}), do: "You have been signed out due to inactivity"
    ```

### Registerable (TODO)

### Database Authenticatable
1. Run the install command

    ```
    mix curator.database_authenticatable.install
    ```

2. Add to the curator modules (`<my_app_web>/lib/<my_app_web>/auth/curator.ex`)

    ```elixir
    use Curator, otp_app: :<my_app_web>,
      modules: [
       <MyAppWeb>.Auth.DatabaseAuthenticatable,
      ]
    ```

3. Update the user schema (`<my_app>/lib/<my_app>/auth/user.ex`)

    ```elixir
    field :password, :string, virtual: true
    field :password_hash, :string
    ```

4. Add your crypto_mod dependencies.

  By default, Comeonin.Bcrypt is configured as the crypto_mod. This requires two dependencies:

    ```
    {:bcrypt_elixir, "~> 1.0"},
    {:comeonin, "~> 4.0"},
    ```

  You can configure the crypto_mod by passing it as an arguement in the DatabaseAuthenticatable implementation.

5. Update the new session page as needed (`<my_app_web>/lib/<my_app_web>/templates/auth/session/new.html.eex`)

6. run the migration

    ```
    mix ecto.migrate
    ```

7. Add a way for users to manage their passwords, like: [Registerable](#registerable)

  If you just want to test the module out, you can use the changeset directly:

  ```elixir
  Houston.Auth.find_user_by_email("eric.sullivan@annkissam.com")
  |> HoustonWeb.Auth.DatabaseAuthenticatable.changeset(%{password: "TEST"})
  |> Houston.Auth.update_user_changeset()
  ```


### Confirmable (TODO)

### Recoverable (TODO)

### Lockable (TODO)

### Approvable (TODO)

### API

#### Description
API Login (with an opaque token)

This generator uses the `Curator.Guardian.Token.Opaque` module in place of the guardian default `Guardian.Token.Jwt`. It also assumes you'll be storing them in an ecto database. Various backends could be used, as long as they implement the Curator.Guardian.Token.Opaque.Persistence behaviour. If you prefer JWT throughout, you can remove the schema / context and set the guardian_token to the default (TODO: accept a command line option to do this).

#### Installation

1. Run the install command

    ```
    mix curator.api.install
    ```

2. Update your router (`<my_app_web>/lib/<my_app_web>/router.ex`)

    ```elixir
    require Curator.Router

    pipeline :api do
      plug :accepts, ["json"]

      plug <MyWebApp>.Auth.Curator.ApiPipeline
    end

    scope "/api", <MyWebApp> do
      pipe_through :api

      ...
    end
    ```

3. Testing

    Update `conn_case.ex`:

    ```elixir
    setup tags do
      ...

      api_unauth_conn = Phoenix.ConnTest.build_conn() |> Plug.Conn.put_req_header("accept", "application/json")

      {:ok, token_id, _claims} = <MyWebApp>.Auth.ApiGuardian.encode_and_sign(auth_user, %{description: "TEST"})
      api_auth_conn = Plug.Conn.put_req_header(api_unauth_conn, "authorization", "Bearer: #{token_id}")

      api_invalid_conn = Plug.Conn.put_req_header(api_unauth_conn, "authorization", "Bearer: NOT_A_REAL_TOKEN")

      {:ok,
        ...
        api_unauth_conn: api_unauth_conn,
        api_auth_conn: api_auth_conn,
        api_invalid_conn: api_invalid_conn,
      }
    end
    ```

    To test, I created some special routes:

    ```elixir
    scope "/api", <MyAppWeb> do
      pipe_through :api

      if Mix.env == :test do
        get "/secure", PageController, :json_secure
      end
    ```

    Update the `page_controller.ex`:

    ```elixir
    defmodule <MyAppWeb>.PageController do
      use <MyAppWeb>, :controller

      def json_secure(conn, _params) do
        json conn, %{data: "SECURE"}
      end
    end
    ```

    And wrote tests in `page_controller_test.exs`:

    ```
    defmodule <MyAppWeb>.PageControllerTest do
      use <MyAppWeb>.ConnCase

      describe "API" do
        test "GET /secure (Unauthenticated)", %{api_unauth_conn: conn} do
          conn = get conn, "/api/secure"
          assert json_response(conn, 403) == %{"error" => "No API Token"}
        end

        test "GET /secure (Authenticated)", %{api_auth_conn: conn} do
          conn = get conn, "/api/secure"
          assert json_response(conn, 200) == %{"data" => "SECURE"}
        end

        test "GET /secure (Bad Token)", %{api_invalid_conn: conn} do
          conn = get conn, "/api/secure"
          assert json_response(conn, 403) == %{"error" => "Invalid API Token"}
        end
      end
    end
    ```

# Extending Curator (TODO)

# Debt
Thanks go out to the [Phoenix Team](https://github.com/phoenixframework/phoenix), the original rails gem [Devise](https://github.com/plataformatec/devise), [Guardian](https://github.com/ueberauth/guardian), and the other elixir authentication solutions:

* [Coherence](https://github.com/smpallen99/coherence)
* [Sentinel](https://github.com/britton-jb/sentinel)
* [Openmaize](https://github.com/riverrun/openmaize)

Any decent ideas I credit to them, I was just acting as the curator.
