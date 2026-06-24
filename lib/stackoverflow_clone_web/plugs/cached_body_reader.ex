defmodule StackoverflowCloneWeb.Plugs.CachedBodyReader do
  @moduledoc """
  Caches the raw request body in conn.assigns[:raw_body] before the parser
  consumes it. Required so VerifySlackSignature can compute HMAC over the
  original bytes.
  """

  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = Plug.Conn.assign(conn, :raw_body, body)
    {:ok, body, conn}
  end
end
