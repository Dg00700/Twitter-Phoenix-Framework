defmodule Twitter5Web.Router do
  use Twitter5Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Twitter5Web do
    pipe_through :browser

    get "/", PageController, :login
    get "/home", PageController, :homepage
    get "/searchquery", PageController, :searchquery
  end

  # Other scopes may use custom stacks.
  # scope "/api", TwitterWeb do
  #   pipe_through :api
  # end
end
