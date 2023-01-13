defmodule ShipWeb.Router do
  use ShipWeb, :router

  import ShipWeb.PlayerAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ShipWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_player
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ShipWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", ShipWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ShipWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ShipWeb do
    pipe_through [:browser, :redirect_if_player_is_authenticated]

    get "/players/register", PlayerRegistrationController, :new
    post "/players/register", PlayerRegistrationController, :create
    get "/players/log_in", PlayerSessionController, :new
    post "/players/log_in", PlayerSessionController, :create
    get "/players/reset_password", PlayerResetPasswordController, :new
    post "/players/reset_password", PlayerResetPasswordController, :create
    get "/players/reset_password/:token", PlayerResetPasswordController, :edit
    put "/players/reset_password/:token", PlayerResetPasswordController, :update
  end

  scope "/", ShipWeb do
    pipe_through [:browser, :require_authenticated_player]

    live "/game", GameLive
    get "/players/settings", PlayerSettingsController, :edit
    put "/players/settings", PlayerSettingsController, :update
    get "/players/settings/confirm_email/:token", PlayerSettingsController, :confirm_email
  end

  scope "/", ShipWeb do
    pipe_through [:browser]

    delete "/players/log_out", PlayerSessionController, :delete
    get "/players/confirm", PlayerConfirmationController, :new
    post "/players/confirm", PlayerConfirmationController, :create
    get "/players/confirm/:token", PlayerConfirmationController, :edit
    post "/players/confirm/:token", PlayerConfirmationController, :update
  end
end
