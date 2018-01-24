defmodule <%= inspect context.web_module %>.Auth.Curator do
  use Curator, otp_app: :<%= Mix.Phoenix.otp_app() %>,
    guardian: <%= inspect context.web_module %>.Auth.Guardian,
    modules: []

  defmodule <%= inspect context.web_module %>.Auth.Curator.UnauthenticatedPipeline do
    use Plug.Builder

    plug Guardian.Plug.Pipeline, module: <%= inspect context.web_module %>.Auth.Guardian,
                                 error_handler: <%= inspect context.web_module %>.Auth.ErrorHandler

    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource, allow_blank: true
  end

  defmodule <%= inspect context.web_module %>.Auth.Curator.AuthenticatedPipeline do
    use Plug.Builder

    plug Guardian.Plug.Pipeline, module: <%= inspect context.web_module %>.Auth.Guardian,
                                 error_handler: <%= inspect context.web_module %>.Auth.ErrorHandler

    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
  end
end
