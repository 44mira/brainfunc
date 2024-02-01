defmodule Bfi do
  @moduledoc """
  Brainf\*ck Interpreter in Elixir.

  Wanted to try my hand at parsing a language. Imperatively, Brainf\*ck is trivial to interpret,
  which is why I wanted to try it in a functional language like Elixir.

  ## Examples

  Linux

  ```bash
    $> ./bfi hello.txt
    Hello world!
    $> ./bfi --eval --size=10 "++++++[>+++++++++<-]>.+++."
    69
  ```

  Windows

  ```cmd
    $> escript bfi hello.txt
    Hello world!
    $> escript bfi --eval --size=10 "++++++[>+++++++++<-]>.+++."
    69
  ```
  """
  @env %{
    ?+ => :increment,
    ?- => :decrement,
    ?> => :next,
    ?< => :prev,
    ?. => :print,
    ?, => :input,
  }

  @doc """
  Creates the initial state for `eval/2`, based on a given `size`

  ## Examples

      iex> init = Bfi.memory(3)
      iex> Bfi.parse("++++++[>++++++++<-]>.") |> Bfi.eval(init)
      {1, {:array, 3, 0, 0, {0, 48, 0, 0, 0, 0, 0, 0, 0, 0}}, ""}
      iex> Bfi.parse("-[>-[-]]<") |> Bfi.eval(Bfi.memory(5))
      {0, {:array, 5, 0, 0, {255, 0, 0, 0, 0, 0, 0, 0, 0, 0}}, ""}

  """
  def memory(size), do: {0, :array.new(size, default: 0), ""}

  def main(args) do
    {switches, arg, _invalid}= OptionParser.parse(args, switches: [eval: :boolean, size: :integer])

    input = if switches[:eval], do: :erlang.iolist_to_binary(arg), else: File.read!(arg)

    input
    |> parse
    |> eval(memory(Keyword.get(switches, :size, 100)))

  end

  @doc """
  Parse characters into tokens and group loops.

  > Since Brainf\*ck tokens are just characters, lexing can be condensed into this one function.

  | Character   | Meaning                                            |
  | ----------  | -------------------------------------------------- |
  | `+`         | Increments the current cell                        |
  | `-`         | Decrements the current cell                        |
  | `>`         | Moves forward by one cell                          |
  | `<`         | Moves backward by one cell                         |
  | `.`         | Outputs the current cell                           |
  | `,`         | Takes an integer input                             |
  | `[`         | When current cell is 0, jump to after matching `]` |
  | `]`         | Jump unconditionally to matching `[`               |
  | `<other>`   | Read as a comment                                  |

  ## Tokens

  ```
  @env %{
    ?+ => :increment,
    ?- => :decrement,
    ?> => :next,
    ?< => :prev,
    ?. => :print,
    ?, => :input,
  }
  ```

  Brackets are parsed as nested lists.

  ## Examples

      iex> Bfi.parse("++.a")
      [:increment, :increment, :print, :comment]
      iex> Bfi.parse("-><")
      [:decrement, :next, :prev]
      iex> Bfi.parse("-[--].")
      [:decrement, [:decrement, :decrement], :print]

  """
  def parse(instruction, acc \\ [])
  def parse("", acc), do: Enum.reverse(acc)
  def parse("[" <> next , acc) do
    {rem, res} = parse(next, [])
    parse(rem, [res | acc])
  end
  def parse("]" <> next, acc), do: {next, Enum.reverse(acc)}
  def parse(<<head::8>> <> next, acc), do: parse(next, [Map.get(@env, head, :comment) | acc])

  @doc """
  Evaluation function that comes after the parsing step.

  Uses tail-recursion with the state as the accumulator.

  ## State

  The state is a 3-tuple, composed of the data pointer `dp`, the memory `mem`, and the input queue `input`.

  ## Notes

  - Elixir raises an error when trying to `:print` ASCII values that are greater than 128.
  - Inputting more than one character after an evaluation on `:input` results in queueing the rest of the input for subsequent `:input` calls.
  - When evaluating `:next` and `:prev`, note that `dp` is bounded by 0 and the size of `mem`.
  - When evaluating `:increment` and `:decrement`, note that negative values underflow to 255, and numbers greater than 255 overflow back to 0.

  ## Examples

      iex> Bfi.parse("++++++[>++++++++<-]>.>++++++++++.") |> Bfi.eval(Bfi.memory(3))
      0
      {2, {:array, 3, 0, 0, {0, 48, 10, 0, 0, 0, 0, 0, 0, 0}}, ""}
      iex> Bfi.parse(",.,.>++++++++++.") |> Bfi.eval(Bfi.memory(3))
      01
      01
      {1, {:array, 3, 0, 0, {49, 10, 0, 0, 0, 0, 0, 0, 0, 0}}, ""}

  """
  def eval([], state), do: state
  def eval([:comment | next], state), do: eval(next, state)
  def eval([:next | next], {dp, mem, input}), do: eval(next, {min(dp + 1, :array.size(mem)), mem, input})
  def eval([:prev | next], {dp, mem, input}), do: eval(next, {max(dp - 1, 0), mem, input})
  def eval([:increment | next], {dp, mem, input}) do
    curr = :array.get(dp, mem)
    new_mem = :array.set(dp, rem(curr + 1, 256), mem)       # overflow
    eval(next, {dp, new_mem, input})
  end
  def eval([:decrement | next], {dp, mem, input}) do
    curr = :array.get(dp, mem)
    new_mem = :array.set(dp, rem(curr + 255, 256), mem)     # underflow
    eval(next, {dp, new_mem, input})
  end
  def eval([:print | next], {dp, mem, input}) do
    curr = :array.get(dp, mem)
    IO.write(<<curr>>)
    eval(next, {dp, mem, input})
  end
  def eval([:input | next], {dp, mem, ""}) do
    getc = IO.gets("") |> String.trim
    eval([:input | next], {dp, mem, getc})
  end
  def eval([:input | next], {dp, mem, <<c::size(8)>> <> input}) do
    new_mem = :array.set(dp, c, mem)
    eval(next, {dp, new_mem, input})
  end
  def eval([loop | next], state) do
    new_state = {new_dp, new_mem, _new_input} = eval(loop, state)
    if :array.get(new_dp, new_mem) == 0 do
      eval(next, new_state)
    else
      eval([loop | next], new_state)
    end
  end

end
