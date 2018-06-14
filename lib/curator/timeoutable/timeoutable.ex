defmodule Curator.Timeoutable do
  use Curator.Extension

  alias Guardian.Plug.Pipeline

  @default_key "default"

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config, unquote(opts)
      use Curator.Extension, mod: Curator.Timeoutable

      def update_timeoutable_timestamp(conn, opts \\ []) do
        Curator.Timeoutable.update_timeoutable_timestamp(conn, opts)
      end

      def verify_timeoutable_timestamp(conn, opts \\ []) do
        Curator.Timeoutable.verify_timeoutable_timestamp(__MODULE__, conn, opts)
      end
    end
  end

  # Config
  def timeout_in(mod) do
    apply(mod, :config, [:timeout_in, 1800])
  end

  # Extensions
  def after_sign_in(conn, _user, opts) do
    update_timeoutable_timestamp(conn, opts)
  end

  # Plug Helpers
  def update_timeoutable_timestamp(conn, opts \\ []) do
    put_timeoutable_timestamp(conn, Curator.Time.timestamp(), opts)
  end

  def verify_timeoutable_timestamp(mod, conn, opts \\ []) do
    last_request_at = get_timeoutable_timestamp(conn, opts)
    timeout_in = timeout_in(mod)

    verify_exp(timeout_in, last_request_at)
  end

  # Private

  defp put_timeoutable_timestamp(conn, timestamp, opts) do
    key = fetch_timeoutable_key(conn, opts)
    Plug.Conn.put_session(conn, key, timestamp)
  end

  defp get_timeoutable_timestamp(conn, opts) do
    key = fetch_timeoutable_key(conn, opts)
    Plug.Conn.get_session(conn, key)
  end

  defp verify_exp(_, nil), do: false

  defp verify_exp(timeout_in, last_request_at) do
    last_request_at + timeout_in > Curator.Time.timestamp()
  end

  defp fetch_timeoutable_key(conn, opts) do
    conn
    |> fetch_key(opts)
    |> timeoutable_key()
  end

  defp fetch_key(conn, opts) do
    Keyword.get(opts, :key) || Pipeline.current_key(conn) || default_key()
  end

  defp default_key, do: @default_key

  @doc false
  @spec timeoutable_key(String.t() | atom) :: atom
  defp timeoutable_key(key), do: String.to_atom("#{Guardian.Plug.Keys.base_key(key)}_timeoutable")
end
