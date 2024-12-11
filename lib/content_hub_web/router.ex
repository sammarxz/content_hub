defmodule ContentHubWeb.Router do
  use ContentHubWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ContentHubWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", ContentHubWeb do
    pipe_through :browser
    
    live "/", UTMBuilderLive
  end
end