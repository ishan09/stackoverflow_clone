defmodule StackoverflowClone.ReelsTest do
  use ExUnit.Case

  alias StackoverflowClone.Reels
  alias StackoverflowClone.ReelsRepo
  alias StackoverflowClone.Reels.Reel

  @url "https://www.instagram.com/reel/test123/"

  setup do
    # Clean up test reels between tests
    ReelsRepo.delete_all(Reel)
    :ok
  end

  describe "find_or_create/1" do
    test "creates a new reel when URL not seen before" do
      assert {:ok, %Reel{url: @url, status: :pending}} = Reels.find_or_create(@url)
    end

    test "returns existing reel on duplicate URL" do
      {:ok, reel1} = Reels.find_or_create(@url)
      {:ok, reel2} = Reels.find_or_create(@url)
      assert reel1.id == reel2.id
    end
  end

  describe "update_status/2" do
    test "updates reel status" do
      {:ok, reel} = Reels.find_or_create(@url)
      assert {:ok, updated} = Reels.update_status(reel, :processing)
      assert updated.status == :processing
    end
  end

  describe "mark_processed/2" do
    test "saves all result fields" do
      {:ok, reel} = Reels.find_or_create(@url)

      result = %{
        caption: "A caption",
        transcript: "A transcript",
        processed_input: "[CAPTION]\nA caption",
        summary: "The summary",
        raw_metadata: %{"title" => "Test"}
      }

      assert {:ok, processed} = Reels.mark_processed(reel, result)
      assert processed.status == :processed
      assert processed.caption == "A caption"
      assert processed.transcript == "A transcript"
      assert processed.summary == "The summary"
    end
  end

  describe "mark_failed/1" do
    test "marks an existing reel as failed" do
      {:ok, _reel} = Reels.find_or_create(@url)
      assert :ok = Reels.mark_failed(@url)
      {:ok, reel} = Reels.get_by_url(@url)
      assert reel.status == :failed
    end

    test "is a no-op for unknown URL" do
      assert :ok = Reels.mark_failed("https://www.instagram.com/reel/unknown/")
    end
  end

  describe "get_by_url/1" do
    test "returns reel when found" do
      {:ok, _} = Reels.find_or_create(@url)
      assert {:ok, %Reel{}} = Reels.get_by_url(@url)
    end

    test "returns error when not found" do
      assert {:error, :not_found} = Reels.get_by_url("https://www.instagram.com/reel/nope/")
    end
  end

  describe "list_reels/1" do
    test "returns reels in descending insertion order" do
      url1 = "https://www.instagram.com/reel/first/"
      url2 = "https://www.instagram.com/reel/second/"
      {:ok, _} = Reels.find_or_create(url1)
      {:ok, _} = Reels.find_or_create(url2)

      [latest | _] = Reels.list_reels()
      assert latest.url == url2
    end

    test "filters by status" do
      {:ok, reel} = Reels.find_or_create(@url)
      Reels.update_status(reel, :processing)

      processing = Reels.list_reels(status: :processing)
      assert Enum.any?(processing, &(&1.url == @url))

      pending = Reels.list_reels(status: :pending)
      refute Enum.any?(pending, &(&1.url == @url))
    end

    test "respects limit option" do
      for i <- 1..5 do
        Reels.find_or_create("https://www.instagram.com/reel/item#{i}/")
      end

      assert length(Reels.list_reels(limit: 3)) == 3
    end
  end
end
