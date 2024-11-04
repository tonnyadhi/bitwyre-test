defmodule CoinPriceServiceTest do
  use ExUnit.Case
  doctest CoinPriceService

  test "greets the world" do
    assert CoinPriceService.hello() == :world
  end
end
