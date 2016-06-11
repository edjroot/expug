defmodule ExslimTokenizerTest do
  use ExUnit.Case

  import Exslim.Tokenizer, only: [tokenize: 1]
  import Enum, only: [reverse: 1]

  test "basic" do
    {:ok, output} = tokenize("head")
    assert reverse(output) == [
      {0, :indent, ""},
      {0, :element_name, "head"}
    ]
  end

  test "basic with text" do
    {:ok, output} = tokenize("title Hello world")
    assert reverse(output) == [
      {0, :indent, ""},
      {0, :element_name, "title"},
      {6, :sole_raw_text, "Hello world"}
    ]
  end

  test "title= name" do
    {:ok, output} = tokenize("title= name")
    assert reverse(output) == [
      {0, :indent, ""},
      {0, :element_name, "title"},
      {7, :sole_buffered_text, "name"}
    ]
  end

  test "multiline" do
    {:ok, output} = tokenize("head\nbody\n")
    assert reverse(output) == [
      {0, :indent, ""},
      {0, :element_name, "head"},
      {5, :indent, ""},
      {5, :element_name, "body"},
    ]
  end

  test "multiline with blank lines" do
    {:ok, output} = tokenize("head\n   \n  \nbody\n")
    assert reverse(output) == [
      {0, :indent, ""},
      {0, :element_name, "head"},
      {12, :indent, ""},
      {12, :element_name, "body"},
    ]
  end

  test "div[]" do
    {:ok, output} = tokenize("div[]")
    assert reverse(output) == [
      {0, :indent, ""},
      {0, :element_name, "div"},
      {3, :attribute_open, "["},
      {4, :attribute_close, "]"}
    ]
  end

  test "div()" do
    {:ok, output} = tokenize("div()")
    assert reverse(output) == [
      {0, :indent, ""},
      {0, :element_name, "div"},
      {3, :attribute_open, "("},
      {4, :attribute_close, ")"}
    ]
  end

  test "div(id=\"hi\")" do
    {:ok, output} = tokenize("div(id=\"hi\")")
    assert reverse(output) == [
      {0, :indent, ""},
      {0, :element_name, "div"},
      {3, :attribute_open, "("},
      {4, :attribute_key, "id"},
      {7, :attribute_value, "\"hi\""},
      {11, :attribute_close, ")"}
    ]
  end

  test "div(id=\"hi\" class=\"foo\")" do
    {:ok, output} = tokenize("div(id=\"hi\" class=\"foo\")")
    assert reverse(output) == [
      {0, :indent, ""},
      {0, :element_name, "div"},
      {3, :attribute_open, "("},
      {4, :attribute_key, "id"},
      {7, :attribute_value, "\"hi\""},
      {12, :attribute_key, "class"},
      {18, :attribute_value, "\"foo\""},
      {23, :attribute_close, ")"}
    ]
  end

  test "class" do
    {:ok, output} = tokenize("div.blue")
    assert reverse(output) == [
      {0, :indent, ""},
      {0, :element_name, "div"},
      {4, :element_class, "blue"}
    ]
  end

  test "classes" do
    {:ok, output} = tokenize("div.blue.sm")
    assert reverse(output) == [
      {0, :indent, ""},
      {0, :element_name, "div"},
      {4, :element_class, "blue"},
      {9, :element_class, "sm"}
    ]
  end

  test "classes and ID" do
    {:ok, output} = tokenize("div.blue.sm#box")
    assert reverse(output) == [
      {0, :indent, ""},
      {0, :element_name, "div"},
      {4, :element_class, "blue"},
      {9, :element_class, "sm"},
      {12, :element_id, "box"}
    ]
  end

  test "parse error" do
    {:error, output} = tokenize("huh?")
    assert output == {:parse_error, 3, [:eof]}
  end

  test "| raw text" do
    {:ok, output} = tokenize("| text")
    assert reverse(output) == [
      {0, :indent, ""},
      {2, :raw_text, "text"}
    ]
  end

  test "= buffered text" do
    {:ok, output} = tokenize("= text")
    assert reverse(output) == [
      {0, :indent, ""},
      {2, :buffered_text, "text"}
    ]
  end

  test "- statement" do
    {:ok, output} = tokenize("- text")
    assert reverse(output) == [
      {0, :indent, ""},
      {2, :statement, "text"}
    ]
  end

  test "doctype" do
    {:ok, output} = tokenize("doctype html5\nhtml")
    assert reverse(output) == [
      {8, :doctype, "html5"},
      {14, :indent, ""},
      {14, :element_name, "html"}
    ]
  end

  # test "doctype"
  # test "true expressions [foo=(a + b)]"
  # test "comma delimited attributes"
  # test "script."
end
