defmodule <%= inspect context.web_module %>.Auth.Confirmable do
  use Curator.Confirmable,
    otp_app: :<%= Mix.Phoenix.otp_app() %>,
    curator: <%= inspect context.web_module %>.Auth.Curator
end
