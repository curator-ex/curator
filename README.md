# Curator

An Authentication Framework for Phoenix.

Curator is meant to mimic [Devise](https://github.com/plataformatec/devise), as such it provides [several modules](#curator-modules) to accomplish authentication and various aspects of user lifecycle mangement (see modules below). It's build with a module architecture that differs from existing Elixir Authentication solutions. Each curator module is a separate Hex package which can be combined to handle various authentication scenarios, passing coordination though a [CuratorHooks module](#curator-hooks-module).

TODO: Curator uses [Guardian](https://github.com/ueberauth/guardian) for session management. However, a JWT approach may be inappropriate for some applications, and so API and Browser [session management](#session-management) is configurable.

For an example, see the [PhoenixCurator Application](https://github.com/curator-ex/phoenix_curator)

## Curator Modules

* [Timeoutable](https://github.com/curator-ex/curator_timeoutable): Session Timeout (after configurable inactivity).
* [Recoverable](https://github.com/curator-ex/curator_recoverable): Reset the User Password.
* [Lockable](https://github.com/curator-ex/curator_lockable): Lock Account after configurbale count of invalid sign-ins.
* [Database Authenticatable](https://github.com/curator-ex/curator_database_authenticatable): Compare a password to a hashed password to support password based sign-in.
* [Confirmable](https://github.com/curator-ex/curator_confirmable): Account email verification.
* [Approvable](https://github.com/curator-ex/curator_approvable): Require an approval step before user sign-in.

TODO:
* [Browser Sessionable](https://github.com/curator-ex/browser_sessionable): Allow browser sign-in based sessions.

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
      mix curator.install
    ```

## Curator Hooks Module

## Session Management

### Guardian

1. `mix.exs`

  ```elixir
  def deps do
    [{:guardian, "~> 0.14"}]
  end
  ```

3. `config.exs`

  ```elixir
  config :guardian, Guardian,
    issuer: "AuthApp",
    ttl: { 1, :days },
    allowed_drift: 2000,
    verify_issuer: true,
    secret_key: <guardian secret key>,
    serializer: AuthApp.GuardianSerializer
  ```


