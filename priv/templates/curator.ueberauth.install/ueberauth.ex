defmodule <%= inspect context.web_module %>.Auth.Ueberauth do
  use Curator.Ueberauth, otp_app: :<%= Mix.Phoenix.otp_app() %>
end
