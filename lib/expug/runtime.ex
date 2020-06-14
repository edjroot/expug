defmodule Expug.Runtime do
  @moduledoc """
  Functions used by Expug-compiled templates at runtime.

  ```eex
  <div class=<%= raw(Expug.Runtime.attr_value(str)) %>></div>
  ```
  """

  @doc """
  Stringifies a given `val` for use as an HTML attribute value.
  """
  def attr_value(val) do
    "\"#{attr_value_escape("#{val}")}\""
  end

  def attr_value_escape(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("\"", "&quot;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  def attr(key, true) do
    " " <> key
  end

  def attr(_key, false) do
    ""
  end

  def attr(_key, nil) do
    ""
  end

  def attr(key, value) do
    " " <> key <> "=" <> attr_value(value)
  end
end
