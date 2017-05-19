# Überauth Dropbox

Dropbox OAuth2 strategy for Überauth.

## Installation

1. Setup your application at [Dropbox Developer](https://www.dropbox.com/developers/apps).

1. Add `:ueberauth_dropbox` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_dropbox, "~> 0.1"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_dropbox]]
    end
    ```

1. Add Dropbox to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        dropbox: {Ueberauth.Strategy.Dropbox, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Dropbox.OAuth,
      client_id: System.get_env("DROPBOX_CLIENT_ID"),
      client_secret: System.get_env("DROPBOX_CLIENT_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller

      pipeline :browser do
        plug Ueberauth
        ...
       end
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. You controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initial the request through:

    /auth/dropbox

## License

Please see [LICENSE](https://github.com/ryotsu/ueberauth_dropbox/blob/master/LICENSE) for licensing details.
