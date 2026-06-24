defmodule StackoverflowClone.ContentAssemblerTest do
  use ExUnit.Case, async: true

  alias StackoverflowClone.ContentAssembler

  describe "build_input/2" do
    test "combines caption and transcript" do
      {:ok, result} = ContentAssembler.build_input("A caption", "A transcript")
      assert result =~ "[CAPTION]"
      assert result =~ "A caption"
      assert result =~ "[TRANSCRIPT]"
      assert result =~ "A transcript"
    end

    test "works with caption only" do
      {:ok, result} = ContentAssembler.build_input("Only caption", nil)
      assert result =~ "[CAPTION]"
      assert result =~ "Only caption"
      refute result =~ "[TRANSCRIPT]"
    end

    test "works with transcript only" do
      {:ok, result} = ContentAssembler.build_input(nil, "Only transcript")
      refute result =~ "[CAPTION]"
      assert result =~ "[TRANSCRIPT]"
      assert result =~ "Only transcript"
    end

    test "returns error when both are nil" do
      assert {:error, :no_usable_content} = ContentAssembler.build_input(nil, nil)
    end

    test "returns error when both are empty strings" do
      assert {:error, :no_usable_content} = ContentAssembler.build_input("", "")
    end

    test "returns error when caption is only whitespace and transcript nil" do
      assert {:error, :no_usable_content} = ContentAssembler.build_input("   ", nil)
    end

    test "strips hashtags from caption" do
      {:ok, result} = ContentAssembler.build_input("Great video #trending #fyp", nil)
      refute result =~ "#trending"
      refute result =~ "#fyp"
      assert result =~ "Great video"
    end

    test "does NOT strip hashtags from transcript" do
      {:ok, result} = ContentAssembler.build_input(nil, "The tag #trending appeared")
      assert result =~ "#trending"
    end

    test "returns error when caption becomes empty after stripping hashtags" do
      assert {:error, :no_usable_content} = ContentAssembler.build_input("#hashtag1 #hashtag2", nil)
    end
  end

  describe "assemble/1" do
    test "supports arbitrary source types" do
      {:ok, result} = ContentAssembler.assemble([{:ocr, "Text from frame"}])
      assert result =~ "[FRAME TEXT]"
      assert result =~ "Text from frame"
    end

    test "skips nil sources" do
      {:ok, result} = ContentAssembler.assemble([{:caption, "Hello"}, {:transcript, nil}])
      assert result =~ "[CAPTION]"
      refute result =~ "[TRANSCRIPT]"
    end

    test "returns error for all-nil sources" do
      assert {:error, :no_usable_content} =
               ContentAssembler.assemble([{:caption, nil}, {:transcript, nil}])
    end

    test "unknown type gets uppercase bracket header" do
      {:ok, result} = ContentAssembler.assemble([{:my_custom_type, "content"}])
      assert result =~ "[MY CUSTOM TYPE]"
    end
  end
end
