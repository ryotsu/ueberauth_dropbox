defmodule Ueberauth.Strategy.Dropbox do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with Dropbox.

  ### Setup

  Create an application in Dropbox for you to use.

  Register a new application at:
  [your dropbox developer page](https://www.dropbox.com/developers/apps)
  and get the `client_id` and `client_secret`.

  Include the provider in your configuration for Ueberauth

      config :ueberauth, Ueberauth,
        providers: [
          dropbox: { Ueberauth.Strategy.Dropbox, [] }
        ]

  Then include the configuration for dropbox.

      config :ueberauth, Ueberauth.Strategy.Dropbox.OAuth,
        client_id: System.get_env("DROPBOX_CLIENT_ID"),
        client_secret: System.get_env("DROPBOX_CLIENT_SECRET")

  If you haven't already, create a pipeline and setup routes for your callback
  handler

      pipeline :auth do
        Ueberauth.plug "/auth"
      end

      scope "/auth" do
        pipe_through [:browser, :auth]

        get "/:provider/callback", AuthController, :callback
      end

  Create an endpoint for the callback where you will handle the `Ueberauth.Auth`
  struct

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller

        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end

        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth
        end
      end

  You can edit the behaviour of the Strategy by including some options when you register your provider.

  To set the `uid_field`

      config :ueberauth, Ueberauth,
        providers: [
          dropbox: { Ueberauth.Strategy.Dropbox, [uid_field: :email] }
        ]

  Default is `:account_id`
  """

  use Ueberauth.Strategy, uid_field: :account_id,
                          oauth2_module: Ueberauth.Strategy.Dropbox.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra
  alias Ueberauth.Strategy.Dropbox.OAuth

  @doc """
  Handles the initial redirect to the dropbox authentication page.
  """
  def handle_request!(conn) do
    opts = [redirect_uri: callback_url(conn), token_access_type: "offline"]
    |> with_state_param(conn)
    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from Dropbox. When there is a failure from Dropbox, the
  failure is included in the `ueberauth_failure` struct. Otherwise the
  information returned from Dropbox is returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [[code: code,
                                         redirect_uri: callback_url(conn)]])

    case token.access_token do
      nil ->
        set_errors!(conn, [error(token.other_params["error"],
                              token.other_params["error_description"])])
      _ ->
        fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Dropbox
  response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:dropbox_user, nil)
    |> put_private(:dropbox_token, nil)
  end

  @doc """
  Fetches the uid field from the Dropbox response. This defaults to the option
  `uid_field` which in-turn defaults to `account_id`.
  """
  def uid(conn) do
    user =
      conn
      |> option(:uid_field)
      |> to_string
    conn.private.dropbox_user[user]
  end

  @doc """
  Includes the credentials from the Dropbox response.
  """
  def credentials(conn) do
    token = conn.private.dropbox_token

    %Credentials{
      token: token.access_token,
      token_type: token.token_type,
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct
  """
  def info(conn) do
    user = conn.private.dropbox_user

    %Info{
      name: user["name"]["display_name"],
      first_name: user["name"]["given_name"],
      last_name: user["name"]["surname"],
      nickname: user["name"]["familiar_name"],
      email: %{
        email: user["email"],
        email_verified: user["email_verified"]
      },
      location: user["country"],
      urls: %{
        avatar_url: user["profile_photo_url"],
      },
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Dropbox
  callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.dropbox_token,
        user: conn.private.dropbox_user,
      }
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :dropbox_token, token)

    case OAuth.post(token, "/users/get_current_account") do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      {:ok, %OAuth2.Response{status_code: _status_code, body: user}} ->
        put_private(conn, :dropbox_user, user)
      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("Oauth2", reason)])
      _ ->
        set_errors!(conn, [error("error", "Some error occured")])
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
