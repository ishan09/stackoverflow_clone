defmodule StackoverflowCloneWeb.Router do
  use StackoverflowCloneWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :slack do
    plug :accepts, ["json"]
    plug StackoverflowCloneWeb.Plugs.VerifySlackSignature
  end

  scope "/api", StackoverflowCloneWeb do
    pipe_through :api

    get "/search", SearchController, :search
    get "/questions/latest", QuestionsController, :latest
    get "/questions/:question_id/answers", SearchController, :answers
  end

  scope "/api/slack", StackoverflowCloneWeb do
    pipe_through :slack

    post "/events", SlackController, :events
  end

  if Application.compile_env(:stackoverflow_clone, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: StackoverflowCloneWeb.Telemetry
    end
  end
end
