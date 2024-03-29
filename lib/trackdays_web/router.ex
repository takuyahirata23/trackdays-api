defmodule TrackdaysWeb.Router do
  use TrackdaysWeb, :router

  import TrackdaysWeb.Auth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TrackdaysWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :set_user do
    plug TrackdaysWeb.Plugs.SetUser
  end

  pipeline :require_user do
    plug TrackdaysWeb.Plugs.RequireUser
  end

  pipeline :require_user_for_user_actions do
    plug TrackdaysWeb.Plugs.RequireUserActions
  end

  scope "/", TrackdaysWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/organizations", TrackdaysWeb do
    pipe_through :browser

    get "/:id", OrganizationsController, :organization
  end

  # Other scopes may use custom stacks.
  # scope "/api", TrackdaysWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:trackdays, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TrackdaysWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  if Mix.env() in [:dev] do
    scope "/" do
      pipe_through [:api, :set_user]
      forward "/graphiql", Absinthe.Plug.GraphiQL, schema: TrackdaysWeb.Schema.Schema
    end
  end

  scope "/" do
    pipe_through [:api, :set_user, :require_user]
    forward "/api/graphql", Absinthe.Plug, schema: TrackdaysWeb.Schema.Schema
  end

  scope "/api", TrackdaysWeb do
    pipe_through [:api]
  end

  scope "/auth", TrackdaysWeb do
    pipe_through [:api]

    post "/login", UserSessionController, :login
    post "/register", UserSessionController, :register
    post "/forgot-password", UserSessionController, :create_password_update_request
    get "/verify/:id", UserSessionController, :verify
    get "/verify-new-email/:id", UserSessionController, :verify_new_email

    pipe_through [:require_user_for_user_actions]
    post "/delete-account", UserSessionController, :delete_account
    post "/update-email", UserSessionController, :update_email
  end

  scope "/images", TrackdaysWeb do
    pipe_through [:api, :require_user_for_user_actions]

    post "/profile", ImageController, :profile
  end

  scope("/accounts", TrackdaysWeb) do
    pipe_through [:browser]
    get "/verification_success", AccountController, :verification_success
    get "/verification_fail", AccountController, :verification_fail
    get "/delete", AccountController, :delete_account_request
    post "/delete", AccountController, :delete_account

    live "/forgot-password/:id", PasswordUpdateLive
  end

  scope "/admin", TrackdaysWeb do
    pipe_through [:browser]

    live_session :unauthorized_admin,
      layout: {TrackdaysWeb.Layouts, :admin} do
      live "/login", Admin.LoginLive
    end

    post "/login", AdminSessionController, :create
  end

  scope "/admin", TrackdaysWeb do
    pipe_through [:browser, :require_admin_user]

    live_session :admin,
      layout: {TrackdaysWeb.Layouts, :admin},
      on_mount: [
        {TrackdaysWeb.Auth, :ensure_admin}
      ] do
      live "/dashboard", Admin.DashboardLive
      live "/vehicle/makes", Admin.MakesLive
      live "/vehicle/makes/:id", Admin.MakeDetailLive
      live "/park/facilities", Admin.FacilitiesLive
      live "/park/facilities/:id", Admin.FacilityDetailLive
      live "/business/organizations", Admin.OrganizationsLive
      live "/business/organizations/:id", Admin.OrganizationDetailLive

      live "/business/organizations/:id/trackdays/:trackday_id/edit",
           Admin.OrganizationTrackdayEdit

      live "/business/register-trackday", Admin.RegisterTrackdayLive
      live "/users/groups", Admin.GroupLive
    end
  end
end
