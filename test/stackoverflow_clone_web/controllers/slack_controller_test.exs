defmodule StackoverflowCloneWeb.SlackControllerTest do
  use StackoverflowCloneWeb.ConnCase
  use Oban.Testing, repo: StackoverflowClone.Repo

  alias StackoverflowClone.Workers.ReelProcessorWorker

  setup %{conn: conn} do
    conn = put_req_header(conn, "content-type", "application/json")
    {:ok, conn: conn}
  end

  describe "POST /api/slack/events — url_verification" do
    test "responds with the challenge", %{conn: conn} do
      body = Jason.encode!(%{"type" => "url_verification", "challenge" => "test-challenge-123"})
      conn = post(conn, ~p"/api/slack/events", body)
      assert json_response(conn, 200) == %{"challenge" => "test-challenge-123"}
    end
  end

  describe "POST /api/slack/events — event_callback" do
    test "enqueues a job for Instagram reel URL", %{conn: conn} do
      with_testing_mode(:manual, fn ->
        event = %{
          "type" => "event_callback",
          "event_id" => "Ev#{System.unique_integer([:positive])}",
          "event" => %{
            "type" => "message",
            "text" => "Check this https://www.instagram.com/reel/ABC123/",
            "channel" => "C123",
            "ts" => "1234567890.123456"
          }
        }

        conn = post(conn, ~p"/api/slack/events", Jason.encode!(event))
        assert response(conn, 200) == ""

        assert_enqueued(worker: ReelProcessorWorker,
                        args: %{url: "https://www.instagram.com/reel/ABC123/",
                                channel: "C123"})
      end)
    end

    test "enqueues a job for YouTube URL", %{conn: conn} do
      with_testing_mode(:manual, fn ->
        event = %{
          "type" => "event_callback",
          "event_id" => "Ev#{System.unique_integer([:positive])}",
          "event" => %{
            "type" => "message",
            "text" => "Watch https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            "channel" => "C123",
            "ts" => "1234567890.123456"
          }
        }

        conn = post(conn, ~p"/api/slack/events", Jason.encode!(event))
        assert response(conn, 200) == ""

        assert_enqueued(worker: ReelProcessorWorker,
                        args: %{url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
                                channel: "C123"})
      end)
    end

    test "ignores bot messages", %{conn: conn} do
      with_testing_mode(:manual, fn ->
        event = %{
          "type" => "event_callback",
          "event_id" => "Ev#{System.unique_integer([:positive])}",
          "event" => %{
            "type" => "message",
            "text" => "https://www.instagram.com/reel/ABC123/",
            "channel" => "C123",
            "ts" => "1234567890.123456",
            "bot_id" => "B123"
          }
        }

        conn = post(conn, ~p"/api/slack/events", Jason.encode!(event))
        assert response(conn, 200) == ""
        refute_enqueued(worker: ReelProcessorWorker)
      end)
    end

    test "ignores text without supported URLs", %{conn: conn} do
      with_testing_mode(:manual, fn ->
        event = %{
          "type" => "event_callback",
          "event_id" => "Ev#{System.unique_integer([:positive])}",
          "event" => %{
            "type" => "message",
            "text" => "hello world no URL here",
            "channel" => "C123",
            "ts" => "1234567890.123456"
          }
        }

        conn = post(conn, ~p"/api/slack/events", Jason.encode!(event))
        assert response(conn, 200) == ""
        refute_enqueued(worker: ReelProcessorWorker)
      end)
    end

    test "deduplicates events with same event_id", %{conn: conn} do
      with_testing_mode(:manual, fn ->
        event_id = "Ev#{System.unique_integer([:positive])}"

        event = %{
          "type" => "event_callback",
          "event_id" => event_id,
          "event" => %{
            "type" => "message",
            "text" => "https://www.instagram.com/reel/DEDUP1/",
            "channel" => "C123",
            "ts" => "1234567890.123456"
          }
        }

        body = Jason.encode!(event)
        conn1 = post(conn, ~p"/api/slack/events", body)
        conn2 = post(conn, ~p"/api/slack/events", body)

        assert response(conn1, 200) == ""
        assert response(conn2, 200) == ""

        # Oban unique constraint: same URL → only 1 job in the period
        jobs = all_enqueued(worker: ReelProcessorWorker)
        url_jobs = Enum.filter(jobs, &(&1.args["url"] == "https://www.instagram.com/reel/DEDUP1/"))
        assert length(url_jobs) == 1
      end)
    end

    test "acknowledges unknown event types", %{conn: conn} do
      conn = post(conn, ~p"/api/slack/events", Jason.encode!(%{"type" => "some_future_type"}))
      assert response(conn, 200) == ""
    end
  end
end
