defmodule <%= inspect context.web_module %>.Auth.Approvable do
  use Curator.Approvable,
    otp_app: :<%= Mix.Phoenix.otp_app() %>,
    curator: <%= inspect context.web_module %>.Auth.Curator
end
