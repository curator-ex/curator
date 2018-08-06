defmodule Curator.Time do
  @moduledoc """
  A Curator Helper Module to determine if Ecto.DateTime's have expired.
  This is usually used to see if a database stored token with a *_at
  timestamp has expired.

  # NOTE: Code taken from https://github.com/smpallen99/coherence/blob/master/web/controllers/controller_helpers.ex
  """

  @doc """
  Test if a datetime has expired.

  Convert the datetime from Ecto.DateTime format to Timex format to do
  the comparison given the time during in opts.

  ## Examples

      expired?(user.expire_at, days: 5)
      expired?(user.expire_at, minutes: 10)

      iex> Ecto.DateTime.utc
      ...> |> Curator.Time.expired?(days: 1)
      false

      iex> Ecto.DateTime.utc
      ...> |> Curator.Time.shift(days: -2)
      ...> |> Ecto.DateTime.cast!
      ...> |> Curator.Time.expired?(days: 1)
      true
  """
  @spec expired?(nil | struct, Keyword.t) :: boolean
  def expired?(nil, _), do: true
  def expired?(datetime, opts) do
    not Timex.before?(Timex.now, shift(datetime, opts))
  end

  @doc """
  Shift a Ecto.DateTime or DateTime

  ## Examples

      iex> Ecto.DateTime.cast!("2016-10-10 10:10:10")
      ...> |> Curator.Time.shift(days: -2)
      ...> |> Ecto.DateTime.cast!
      ...> |> to_string
      "2016-10-08 10:10:10"
  """
  @spec shift(struct, Keyword.t) :: struct
  def shift(%Ecto.DateTime{} = datetime, opts) do
    datetime
    |> Ecto.DateTime.to_erl
    |> Timex.to_datetime
    |> Timex.shift(opts)
  end
  def shift(%DateTime{} = datetime, opts) do
    datetime
    |> Timex.shift(opts)
  end

  @doc """
  Shift a Ecto.DateTime (in the opposite direction).

  ## Examples

      iex> Ecto.DateTime.cast!("2016-10-10 10:10:10")
      ...> |> Curator.Time.unshift(days: 2)
      ...> |> Ecto.DateTime.cast!
      ...> |> to_string
      "2016-10-08 10:10:10"
  """
  @spec unshift(struct, Keyword.t) :: struct
  def unshift(datetime, [{unit, amount}]) do
    shift(datetime, [{unit, 0 - amount}])
  end

  @doc """
  NOTE: Code taken from https://github.com/ueberauth/guardian/blob/master/lib/guardian/utils.ex
  """
  def timestamp do
    {mgsec, sec, _usec} = :os.timestamp
    mgsec * 1_000_000 + sec
  end
end
