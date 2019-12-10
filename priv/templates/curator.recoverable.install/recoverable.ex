defmodule <%= inspect context.web_module %>.Auth.Recoverable do
  use Curator.Recoverable,
    otp_app: :<%= Mix.Phoenix.otp_app() %>,
    curator: <%= inspect context.web_module %>.Auth.Curator
end
