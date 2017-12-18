defmodule <%= base %>.SessionHelper do
  @default_opts [
    store: :cookie,
    key: "foobar",
    encryption_salt: "encrypted cookie salt",
    signing_salt: "signing salt"
  ]

  @secret String.duplicate("abcdef0123456789", 8)
  @signing_opts Plug.Session.init(Keyword.put(@default_opts, :encrypt, false))

  def conn_with_fetched_session(conn) do
    put_in(conn.secret_key_base, @secret)
    |> Plug.Session.call(@signing_opts)
    |> Plug.Conn.fetch_session
  end

  def sign_in(conn, resource, perms \\ %{perms: %{}}) do
    conn
    |> conn_with_fetched_session
    |> Curator.PlugHelper.sign_in(resource)
    |> Curator.after_sign_in(resource)
    |> Curator.Plug.LoadSession.call(%{})
  end

  @<%= singular %>_attrs %{
    email: "test_<%= singular %>@example.com",
  }

  def create_<%= singular %>(<%= singular %>, attrs) do
    <%= singular %>
    |> <%= base %>.<%= scoped %>.changeset(attrs)
    # |> <%= base %>.<%= scoped %>.password_changeset(%{password: "TEST_PASSWORD", password_confirmation: "TEST_PASSWORD"})
    # |> Ecto.Changeset.change(confirmed_at: Timex.now)
    # |> <%= base %>.<%= scoped %>.approvable_changeset(%{approval_at: Timex.now, approval_status: "approved", approver_id: 0})
    |> <%= base %>.Repo.insert!
  end

  def create_active_<%= singular %>, do: create_<%= singular %>(%<%= base %>.<%= scoped %>{}, @<%= singular %>_attrs)

  def sign_in_and_create_<%= singular %>(conn) do
    <%= singular %> = create_active_<%= singular %>
    conn = sign_in(conn, <%= singular %>)
    {conn, <%= singular %>}
  end
end
