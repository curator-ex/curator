defmodule Curator.Time do
  @moduledoc """
  A Curator Helper Module to determine if DateTime's have expired.
  This is usually used to see if a database stored token with a *_at
  timestamp has expired.

  # NOTE: Code originally taken from https://github.com/smpallen99/coherence/blob/master/web/controllers/controller_helpers.ex
  """

  @doc """
  Test if a datetime has expired.

  Convert the datetime from DateTime format to Timex format to do
  the comparison given the time during in opts.

  ## Examples

      expired?(user.expire_at, days: 5)
      expired?(user.expire_at, minutes: 10)

      iex> DateTime.utc_now
      ...> |> Curator.Time.expired?(days: 1)
      false

      iex> DateTime.utc_now
      ...> |> Curator.Time.shift(days: -2)
      ...> |> Curator.Time.expired?(days: 1)
      true
  """
  @spec expired?(nil | struct, Keyword.t()) :: boolean
  def expired?(nil, _), do: true

  def expired?(datetime, opts) do
    not Timex.before?(Timex.now(), shift(datetime, opts))
  end

  @doc """
  Shift a DateTime

  ## Examples

      iex> DateTime.from_naive!(~N[2016-10-10 10:10:10], "Etc/UTC")
      ...> |> Curator.Time.shift(days: -2)
      ...> |> to_string
      "2016-10-08 10:10:10Z"
  """
  @spec shift(struct, Keyword.t()) :: struct
  def shift(%DateTime{} = datetime, opts) do
    datetime
    |> Timex.shift(opts)
  end

  @doc """
  Shift a DateTime (in the opposite direction).

  ## Examples

      iex> DateTime.from_naive!(~N[2016-10-10 10:10:10], "Etc/UTC")
      ...> |> Curator.Time.unshift(days: 2)
      ...> |> to_string
      "2016-10-08 10:10:10Z"
  """
  @spec unshift(struct, Keyword.t()) :: struct
  def unshift(datetime, [{unit, amount}]) do
    shift(datetime, [{unit, 0 - amount}])
  end

  @doc """
  NOTE: Code taken from https://github.com/ueberauth/guardian/blob/master/lib/guardian/utils.ex
  """
  def timestamp do
    {mgsec, sec, _usec} = :os.timestamp()
    mgsec * 1_000_000 + sec
  end
end
