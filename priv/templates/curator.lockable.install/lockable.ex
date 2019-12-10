defmodule <%= inspect context.web_module %>.Auth.Lockable do
  use Curator.Lockable,
    otp_app: :<%= Mix.Phoenix.otp_app() %>,
    curator: <%= inspect context.web_module %>.Auth.Curator
end
