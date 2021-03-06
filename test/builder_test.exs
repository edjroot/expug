defmodule BuilderTest do
  use ExUnit.Case
  doctest Expug.Builder

  def build(source) do
    with \
      tokens <- Expug.Tokenizer.tokenize(source),
      ast <- Expug.Compiler.compile(tokens) do
      Expug.Builder.build(ast)
    end
  end

  test "build" do
    eex = build("doctype html\ndiv Hello")
    assert eex == %{
      :lines => 2,
      1 => ["<!doctype html>"],
      2 => ["<div>", "Hello", "</div>"]
    }
  end

  test "self-closing img" do
    eex = build("doctype html\nimg")
    assert eex == %{
      :lines => 2,
      1 => ["<!doctype html>"],
      2 => ["<img>"]
    }
  end

  test "self-closing xml" do
    eex = build("doctype xml\nimg")
    assert eex == %{
      :lines => 2,
      1 => ["<?xml version=\"1.0\" encoding=\"utf-8\" ?>"],
      2 => ["<img />"]
    }
  end

  test "single element" do
    eex = build("div")
    assert eex == %{
      :lines => 1,
      1 => ["<div></div>"]
    }
  end

  test "single element with attributes" do
    eex = build("div(id=foo)")
    assert eex == %{
      :lines => 1,
      1 => ["<div<%= raw(Expug.Runtime.attr(\"id\", foo)) %>></div>"]
    }
  end

  test "value-less attributes" do
    eex = build("div(src)")
    assert eex == %{
      :lines => 1,
      1 => ["<div<%= raw(Expug.Runtime.attr(\"src\", true)) %>></div>"]
    }
  end

  test "with buffered text" do
    eex = build("div= hola()")
    assert eex == %{
      :lines => 1,
      1 =>["<div>", "<%= hola() %>", "</div>"]
    }
  end

  test "with unescaped text" do
    eex = build("div!= hola()")
    assert eex == %{
      :lines => 1,
      1 => ["<div>", "<%= raw(hola()) %>", "</div>"]
    }
  end

  test "unescaped text only" do
    eex = build("!= hola()")
    assert eex == %{
      :lines => 1,
      1 => ["<%= raw(hola()) %>"]
    }
  end

  test "nesting" do
    eex = build("""
    doctype html
    div
      span= @hello
    """)
    assert eex == %{
      :lines => 3,
      1 =>["<!doctype html>"],
      2 =>["<div>"],
      3 =>["<span>", "<%= @hello %>", "</span>", "</div>"]
    }
  end

  test "line comments" do
    eex = build("""
    div
    -# hi
    div
    """)
    assert eex == %{
      :lines => 3,
      1 => ["<div></div>"],
      3 => ["<div></div>"]
    }
  end

  test "line comments, capturing" do
    eex = build("""
    div
    -# hi
      h1
    """)
    assert eex == %{
      :lines => 1,
      1 => ["<div></div>"]
    }
  end

  test "line comments, capturing 2" do
    eex = build("""
    div
    -# hi
      h1
    span
    """)
    assert eex == %{
      :lines => 4,
      1 => ["<div></div>"],
      4 => ["<span></span>"]
    }
  end

  test "indentation magic" do
    eex = build("""
    div
      h1
        span
          | Hello
    """)
    assert eex == %{
      :lines => 4,
      1 => ["<div>"],
      2 => ["<h1>"],
      3 => ["<span>"],
      4 => ["Hello", "</span>", "</h1>", "</div>"]
    }
  end

  test "indentation magic 2" do
    eex = build("""
    div
      h1
        span
          | Hello
    div
    """)
    assert eex == %{
      :lines => 5,
      1 => ["<div>"],
      2 => ["<h1>"],
      3 => ["<span>"],
      4 => ["Hello", "</span>", "</h1>", "</div>"],
      5 => ["<div></div>"]
    }
  end

  test "attr and =" do
    eex = build("""
    div(role="main")= @hello
    """)
    assert eex == %{
      :lines => 1,
      1 => [
        "<div<%= raw(Expug.Runtime.attr(\"role\", \"main\")) %>>",
        "<%= @hello %>",
        "</div>"
      ]
    }
  end

  test "lone dot" do
    try do
      build(".")
      flunk "should've thrown something"
    catch err ->
      assert %{
        expected: _,
        position: {1, 1},
        type: :parse_error
      } = err
    end
  end

  test "dash" do
    eex = build("-hi")
    assert eex == %{
      :lines => 1,
      1 => ["<% hi %>"]
    }
  end

  test "dash with body" do
    eex = build("- for item <- @list do\n  div")
    assert eex == %{
      :lines => 2,
      1 => ["<% for item <- @list do %>"],
      2 => [:collapse, "<div></div><% end %>"]
    }
  end

  test "unescaped with body" do
    eex = build("!= for item <- @list do\n  div")
    assert eex == %{
      :lines => 2,
      1 => ["<%= raw(for item <- @list do %>"],
      2 => [:collapse, "<div></div><% end) %>"]
    }
  end

  @tag :pending
  test "dash with body, collapsing" do
    eex = build("- for item <- @list do\n  div")
    assert eex == %{
      :lines => 2,
      1 => ["<% for item <- @list do %>"],
      2 => [:collapse, "<div></div><% end %>"]
    }
  end

  test "equal with body" do
    eex = build("= for item <- @list do\n  div")
    assert eex == %{
      :lines => 2,
      1 => ["<%= for item <- @list do %>"],
      2 => [:collapse, "<div></div><% end %>"]
    }
  end

  @tag :pending
  test "equal with body with (" do
    eex = build("= Enum.map(@list, fn item ->\n  div")
    assert eex == %{
      :lines => 2,
      1 => [ "<%= Enum.map(@list, fn item -> %>" ],
      2 => [ "<div></div><% end) %>" ]
    }
  end

  test "if .. else ... end" do
    eex = build("= if @x do\n  div\n- else\n  div")
    assert eex == %{
      :lines => 4,
      1 => ["<%= if @x do %>"],
      2 => [:collapse, "<div></div>"],
      3 => ["<% else %>"],
      4 => [:collapse, "<div></div><% end %>"]
    }
  end

  test "if .. else ... if ... end" do
    eex = build("= if @x do\n  div\n- else\n  div\n= if @y do\n  span\n- else\n  span")
    assert eex == %{
      :lines => 8,
      1 => ["<%= if @x do %>"],
      2 => [:collapse, "<div></div>"],
      3 => ["<% else %>"],
      4 => [:collapse, "<div></div><% end %>"],
      5 => ["<%= if @y do %>"],
      6 => [:collapse, "<span></span>"],
      7 => ["<% else %>"],
      8 => [:collapse, "<span></span><% end %>"]
    }
  end

  test "if .. if ... end" do
    eex = build("= if @x do\n  div\n= if @y do\n  div")
    assert eex == %{
      :lines => 4,
      1 => ["<%= if @x do %>"],
      2 => [:collapse, "<div></div><% end %>"],
      3 => ["<%= if @y do %>"],
      4 => [:collapse, "<div></div><% end %>"]
    }
  end

  test "form_for fn -> ... end" do
    eex = build("= form_for @foo, fn x ->\n  div")
    assert eex == %{
      :lines => 2,
      1 => ["<%= form_for @foo, fn x -> %>"],
      2 => [:collapse, "<div></div><% end %>"],
    }
  end

  test "// comment" do
    eex = build("// hi")
    assert eex == %{
      :lines => 1,
      1 => ["<!-- hi -->"],
    }
  end

  test "// comment, multiline" do
    eex = build("// hi\n  world")
    assert eex == %{
      :lines => 1,
      1 => ["<!-- hi\nworld -->"],
    }
  end

  test "// comment, multiline, empty first line" do
    eex = build("//\n  world")
    assert eex == %{
      :lines => 1,
      1 => ["<!-- \nworld -->"],
    }
  end

  test "// comment, multiline, with stuff after" do
    eex = build("//\n  world\ndiv")
    assert eex == %{
      :lines => 3,
      1 => ["<!-- \nworld -->"],
      3 => ["<div></div>"]
    }
  end

  test "cond do ... end" do
    eex = build("= cond do\n  div")
    assert eex == %{
      :lines => 2,
      1 => ["<%= cond do %>"],
      2 => [:collapse, "<div></div><% end %>"]
    }
  end

  @tag :pending
  test "try do ... catch ... rescue ... after ... end"

  test "extra space" do
    eex = build("div\n ")
    assert eex == %{
      :lines => 1,
      1 => [ "<div></div>" ]
    }
  end
end
