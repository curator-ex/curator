

defmodule <%= inspect context.web_module %>.Auth.Curator.ApiPipeline do
  use Plug.Builder

  plug Guardian.Plug.Pipeline, module: <%= inspect context.web_module %>.Auth.OpaqueGuardian,
                               error_handler: <%= inspect context.web_module %>.Auth.ApiErrorHandler

  plug Guardian.Plug.VerifyHeader, claims: %{typ: "api"}
  plug Curator.Plug.LoadResource
end
