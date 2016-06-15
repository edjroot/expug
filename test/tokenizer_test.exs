defmodule ExpugTokenizerTest do
  use ExUnit.Case

  import Expug.Tokenizer, only: [tokenize: 1]
  import Enum, only: [reverse: 1]

  doctest Expug.Tokenizer

  test "basic" do
    {:ok, output} = tokenize("head")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "head"}
    ]
  end

  test "h1" do
    {:ok, output} = tokenize("h1")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "h1"}
    ]
  end

  test "xml namespace" do
    {:ok, output} = tokenize("html:h1")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "html:h1"}
    ]
  end

  test "dashes" do # but why?
    {:ok, output} = tokenize("Todo-app")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "Todo-app"}
    ]
  end

  test "basic with text" do
    {:ok, output} = tokenize("title Hello world")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "title"},
      {{1, 7}, :raw_text, "Hello world"}
    ]
  end

  test "title= name" do
    {:ok, output} = tokenize("title= name")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "title"},
      {{1, 8}, :buffered_text, "name"}
    ]
  end

  test "| name $200" do
    {:ok, output} = tokenize("| name $200")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 3}, :raw_text, "name $200"}
    ]
  end

  test "multiline" do
    {:ok, output} = tokenize("head\nbody\n")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "head"},
      {{2, 1}, :indent, 0},
      {{2, 1}, :element_name, "body"},
    ]
  end

  test "multiline with blank lines" do
    {:ok, output} = tokenize("head\n   \n  \nbody\n")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "head"},
      {{4, 1}, :indent, 0},
      {{4, 1}, :element_name, "body"},
    ]
  end

  test "div[]" do
    {:ok, output} = tokenize("div[]")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "["},
      {{1, 5}, :attribute_close, "]"}
    ]
  end

  test "div()" do
    {:ok, output} = tokenize("div()")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_close, ")"}
    ]
  end

  test "div(id=\"hi\")" do
    {:ok, output} = tokenize("div(id=\"hi\")")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, "\"hi\""},
      {{1, 12}, :attribute_close, ")"}
    ]
  end

  test "div(id='hi')" do
    {:ok, output} = tokenize("div(id='hi')")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, "'hi'"},
      {{1, 12}, :attribute_close, ")"}
    ]
  end

  test ~S[div(id='\'')] do
    {:ok, output} = tokenize(~S[div(id='\'')])
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, ~S['\'']},
      {{1, 12}, :attribute_close, ")"}
    ]
  end

  test ~S[div(id='hi\'')] do
    {:ok, output} = tokenize(~S[div(id='hi\'')])
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, ~S['hi\'']},
      {{1, 14}, :attribute_close, ")"}
    ]
  end

  test "div(id=\"hi\" class=\"foo\")" do
    {:ok, output} = tokenize("div(id=\"hi\" class=\"foo\")")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, "\"hi\""},
      {{1, 13}, :attribute_key, "class"},
      {{1, 19}, :attribute_value, "\"foo\""},
      {{1, 24}, :attribute_close, ")"}
    ]
  end

  test "class" do
    {:ok, output} = tokenize("div.blue")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 5}, :element_class, "blue"}
    ]
  end

  test "classes" do
    {:ok, output} = tokenize("div.blue.sm")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 5}, :element_class, "blue"},
      {{1, 10}, :element_class, "sm"}
    ]
  end

  test "classes and ID" do
    {:ok, output} = tokenize("div.blue.sm#box")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 5}, :element_class, "blue"},
      {{1, 10}, :element_class, "sm"},
      {{1, 13}, :element_id, "box"}
    ]
  end

  test "parse error" do
    {:error, output} = tokenize("hello\nhuh?")
    assert output == %{
      type: :parse_error,
      position: {2, 4},
      expected: [:eq, :whitespace, :attribute_open]
    }
  end

  test "| raw text" do
    {:ok, output} = tokenize("| text")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 3}, :raw_text, "text"}
    ]
  end

  test "= buffered text" do
    {:ok, output} = tokenize("= text")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 3}, :buffered_text, "text"}
    ]
  end

  test "- statement" do
    {:ok, output} = tokenize("- text")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 3}, :statement, "text"}
    ]
  end

  test "doctype" do
    {:ok, output} = tokenize("doctype html5")
    assert reverse(output) == [
      {{1, 9}, :doctype, "html5"}
    ]
  end

  test "doctype + html" do
    {:ok, output} = tokenize("doctype html5\nhtml")
    assert reverse(output) == [
      {{1, 9}, :doctype, "html5"},
      {{2, 1}, :indent, 0},
      {{2, 1}, :element_name, "html"}
    ]
  end

  test "div(id=(hello))" do
    {:ok, output} = tokenize("div(id=(hello))")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, "(hello)"},
      {{1, 15}, :attribute_close, ")"}
    ]
  end

  test "div(id=(hello(world)))" do
    {:ok, output} = tokenize("div(id=(hello(world)))")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, "(hello(world))"},
      {{1, 22}, :attribute_close, ")"}
    ]
  end

  test "div(id=(hello(worl[]d)))" do
    {:ok, output} = tokenize("div(id=(hello(worl[]d)))")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, "(hello(worl[]d))"},
      {{1, 24}, :attribute_close, ")"}
    ]
  end

  test ~S[div(id="hello #{world}")] do
    {:ok, output} = tokenize(~S[div(id="hello #{world}")])
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, ~S["hello #{world}"]},
      {{1, 24}, :attribute_close, ")"}
    ]
  end

  test ~S[div(id=hello)] do
    {:ok, output} = tokenize(~S[div(id=hello)])
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, "hello"},
      {{1, 13}, :attribute_close, ")"}
    ]
  end

  test "with indent" do
    {:ok, output} = tokenize("head\n  title")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "head"},
      {{2, 1}, :indent, 2},
      {{2, 3}, :element_name, "title"}
    ]
  end

  test ~S[div(src=a id=b)] do
    {:ok, output} = tokenize(~S[div(src=a id=b)])
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "src"},
      {{1, 9}, :attribute_value, "a"},
      {{1, 11}, :attribute_key, "id"},
      {{1, 14}, :attribute_value, "b"},
      {{1, 15}, :attribute_close, ")"}
    ]
  end

  test ~S[div( src=a id=b )] do
    {:ok, output} = tokenize(~S[div( src=a id=b )])
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 6}, :attribute_key, "src"},
      {{1, 10}, :attribute_value, "a"},
      {{1, 12}, :attribute_key, "id"},
      {{1, 15}, :attribute_value, "b"},
      {{1, 17}, :attribute_close, ")"}
    ]
  end

  test ~S[div(src=a, id=b)] do
    {:ok, output} = tokenize(~S[div(src=a, id=b)])
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "src"},
      {{1, 9}, :attribute_value, "a"},
      {{1, 12}, :attribute_key, "id"},
      {{1, 15}, :attribute_value, "b"},
      {{1, 16}, :attribute_close, ")"}
    ]
  end

  test "newline between attributes" do
    {:ok, output} = tokenize("div(src=a,\n  id=b)")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "src"},
      {{1, 9}, :attribute_value, "a"},
      {{2, 3}, :attribute_key, "id"},
      {{2, 6}, :attribute_value, "b"},
      {{2, 7}, :attribute_close, ")"}
    ]
  end

  test "multiline attribute contents" do
    {:ok, output} = tokenize("div(\n  src=a\n  )")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{2, 3}, :attribute_key, "src"},
      {{2, 7}, :attribute_value, "a\n"},
      {{3, 3}, :attribute_close, ")"}
    ]
  end

  test "multiline expressions" do
    {:ok, output} = tokenize("div(src=(a\n  b))")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "src"},
      {{1, 9}, :attribute_value, "(a\n  b)"},
      {{2, 5}, :attribute_close, ")"}
    ]
  end

  test "empty attributes" do
    {:ok, output} = tokenize("div(src=\"\")")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "src"},
      {{1, 9}, :attribute_value, "\"\""},
      {{1, 11}, :attribute_close, ")"}
    ]
  end

  test "-# comments" do
    {:ok, output} = tokenize("div\n-# ...")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{2, 1}, :indent, 0},
      {{2, 4}, :line_comment, "..."}
    ]
  end

  test "-# comments, blank" do
    {:ok, output} = tokenize("div\n-#")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{2, 1}, :indent, 0},
      {{2, 3}, :line_comment, ""}
    ]
  end

  test "-# comments, space" do
    {:ok, output} = tokenize("div\n-# ")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{2, 1}, :indent, 0},
      {{2, 4}, :line_comment, ""}
    ]
  end

  test "-# comments, nesting" do
    {:ok, output} = tokenize("-#\n  foobar")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 3}, :line_comment, ""},
      {{2, 3}, :subindent, "foobar"}
    ]
  end

  test "-// comments, nesting" do
    {:ok, output} = tokenize("-//\n  foobar")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 4}, :line_comment, ""},
      {{2, 3}, :subindent, "foobar"}
    ]
  end

  test "-# comments, nesting and after" do
    {:ok, output} = tokenize("-#\n  foobar\ndiv")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 3}, :line_comment, ""},
      {{2, 3}, :subindent, "foobar"},
      {{3, 1}, :indent, 0},
      {{3, 1}, :element_name, "div"}
    ]
  end

  test "// comments" do
    {:ok, output} = tokenize("div\n// ...")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{2, 1}, :indent, 0},
      {{2, 4}, :html_comment, "..."}
    ]
  end

  test "// comments, nesting" do
    {:ok, output} = tokenize("div\n// ...\n  hi")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{2, 1}, :indent, 0},
      {{2, 4}, :html_comment, "..."},
      {{3, 3}, :subindent, "hi"}
    ]
  end

  # test "comma delimited attributes"
  # test "script."
  # test "comments"
  # test "!="
end
