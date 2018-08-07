defmodule <%= inspect context.web_module %>.Auth.Curator do
  use Curator,
    otp_app: :<%= Mix.Phoenix.otp_app() %>,
    guardian: <%= inspect context.web_module %>.Auth.Guardian,
    opaque_guardian: <%= inspect context.web_module %>.Auth.OpaqueGuardian,
    repo: <%= inspect schema.repo %>,
    user: <%= inspect schema.module %>,
    mailer: <%= inspect context.web_module %>.Mailer,
    email: <%= inspect context.web_module %>.Auth.Email,
    modules: []
end

defmodule <%= inspect context.web_module %>.Auth.Curator.UnauthenticatedPipeline do
  use Plug.Builder

  plug Guardian.Plug.Pipeline, module: <%= inspect context.web_module %>.Auth.Guardian,
                               error_handler: <%= inspect context.web_module %>.Auth.ErrorHandler

  plug Guardian.Plug.VerifySession
  plug Curator.Plug.LoadResource, allow_unauthenticated: true

  # plug Curator.Timeoutable.Plug, timeoutable_module: <%= inspect context.web_module %>.Auth.Timeoutable
end

defmodule <%= inspect context.web_module %>.Auth.Curator.AuthenticatedPipeline do
  use Plug.Builder

  plug Guardian.Plug.Pipeline, module: <%= inspect context.web_module %>.Auth.Guardian,
                               error_handler: <%= inspect context.web_module %>.Auth.ErrorHandler

  plug Guardian.Plug.VerifySession
  plug Curator.Plug.LoadResource

  # plug Curator.Timeoutable.Plug, timeoutable_module: <%= inspect context.web_module %>.Auth.Timeoutable
  # plug Curator.Confirmable.Plug, confirmable_module: <%= inspect context.web_module %>.Auth.Confirmable
  # plug Curator.Approvable.Plug, approvable_module: <%= inspect context.web_module %>.Auth.Approvable
end
