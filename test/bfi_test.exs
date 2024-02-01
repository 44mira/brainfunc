defmodule BfiTest do
  use ExUnit.Case

  doctest Bfi, except: [eval: 2]

  describe "Lexing and Parsing" do
    test "Can parse basic commands" do
      assert Bfi.parse("++.") == [:increment, :increment, :print]
      assert Bfi.parse("-><") == [:decrement, :next, :prev]
      assert Bfi.parse(",>,.<.") == [:input, :next, :input, :print, :prev, :print]
    end

    test "Can parse loops" do
      assert Bfi.parse("[-]") == [[:decrement]]
      assert Bfi.parse("+[-].") == [:increment, [:decrement], :print]
      assert Bfi.parse("++[>+++<-]>.") ==
        [
          :increment, :increment,
          [:next, :increment, :increment, :increment, :prev, :decrement],
          :next, :print
        ]
    end
  end

  describe "Evaluation" do
    test "Can evaluate simple arithmetic" do
      assert {0, {:array, 3, 0, 0, {2, 0, 0, 0, 0, 0, 0, 0, 0, 0}}, ""} =
        Bfi.parse("++.") |> Bfi.eval(Bfi.memory(3))
      assert {0, {:array, 3, 0, 0, {254, 0, 0, 0, 0, 0, 0, 0, 0, 0}}, ""} =
        Bfi.parse("--") |> Bfi.eval(Bfi.memory(3))
      assert {0, {:array, 3, 0, 0, {3, 0, 0, 0, 0, 0, 0, 0, 0, 0}}, ""} =
        Bfi.parse("++++-.") |> Bfi.eval(Bfi.memory(3))
      assert {3, {:array, 5, 0, 0, 10}, ""} =
        Bfi.parse(">.>.>") |> Bfi.eval(Bfi.memory(5))
    end

    test "Can evaluate loops" do
      assert {1, {:array, 3, 0, 0, {0, 48, 0, 0, 0, 0, 0, 0, 0, 0}}, ""} =
        Bfi.parse("++++++[>++++++++<-]>.") |> Bfi.eval(Bfi.memory(3))
      assert {0, {:array, 3, 0, 0, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}}, ""} =
        Bfi.parse("-[-]") |> Bfi.eval(Bfi.memory(3))
      assert {0, {:array, 5, 0, 0, {255, 0, 0, 0, 0, 0, 0, 0, 0, 0}}, ""} =
        Bfi.parse("-[>-[-]]<") |> Bfi.eval(Bfi.memory(5))
    end
  end
end
