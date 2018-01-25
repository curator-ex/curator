defmodule <%= inspect context.web_module %>.Auth.Timeoutable do
  use Curator.Timeoutable, otp_app: :<%= Mix.Phoenix.otp_app() %>
end
