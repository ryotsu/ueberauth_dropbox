defmodule Ueberauth.Strategy.Dropbox.OAuth do
  @moduledoc """
  An implementation of OAuth2 for dropbox.

  To add your `client_id` and `client_secret` include these values in your
  configuration.

      config :ueberauth, Ueberauth.Strategy.Dropbox.OAuth,
        client_id: System.get_env("DROPBOX_CLIENT_ID"),
        client_secret: System.get_env("DROPBOX_CLIENT_SECRET")
  """

  use OAuth2.Strategy

  alias OAuth2.Client
  alias OAuth2.Strategy.AuthCode

  @defaults [
    strategy: __MODULE__,
    site: "https://api.dropboxapi.com/2",
    authorize_url: "https://www.dropbox.com/oauth2/authorize",
    token_url: "https://api.dropboxapi.com/oauth2/token",
  ]

  @doc """
  Construct a client for requests to Dropbox.

  Optionally include any OAuth2 options here to be merged with the defaults.

      Ueberauth.Strategy.Dropbox.OAuth.client(redirect_uri: "http://localhost:4000/auth/dropbox/callback")

  This will be setup automatically for you in `Ueberauth.Strategy.Dropbox`.
  These options are only useful for usage outside the normal callback phase
  of Ueberauth.
  """
  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, Ueberauth.Strategy.Dropbox.OAuth)
    client_opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    json_library = Ueberauth.json_library()

    Client.new(client_opts)
    |> OAuth2.Client.put_serializer("application/json", json_library)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to
  call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client()
    |> Client.authorize_url!(params)
  end

  def post(token, url, headers \\ [], opts \\ []) do
    headers = Keyword.put(headers, :"Content-Type", "application/json")
    [token: token]
    |> client()
    |> Client.post(url, nil, headers, opts)
  end

  def get_token!(params \\ [], options \\ []) do
    headers = Keyword.get(options, :headers, [])
    options = Keyword.get(options, :options, [])

    response =
      options
      |> Keyword.get(:client_options, [])
      |> client()
      |> Client.get_token(params, headers, options)

    case response do
      {:ok, client} ->
        client.token
      {:error, error} ->
        %{access_token: nil, other_params: error.body}
    end
  end

  def authorize_url(client, params) do
    AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param("client_id", client.client_id)
    |> put_param("client_secret", client.client_secret)
    |> put_header("Accept", "application/json")
    |> put_param(:grant_type, "authorization_code")
    |> put_param(:redirect_uri, client.redirect_uri)
    |> merge_params(params)
    |> put_headers(headers)
  end
end
