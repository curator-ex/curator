defmodule <%= inspect context.web_module %>.Auth.Registerable do
  use Curator.Registerable, otp_app: :<%= Mix.Phoenix.otp_app() %>
end
