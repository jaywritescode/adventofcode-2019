require "minitest/autorun"
require_relative "intcode"

class ComputerTest < Minitest::Test
  def test_add
    c = Computer.new
    c.set_memory [1001, 5, 6, 5, 99, 11]

    c.start
    assert_equal [1001, 5, 6, 5, 99, 17], c.memory
  end

  def test_multiply
    c = Computer.new
    c.set_memory [1002, 5, 6, 5, 99, 11]

    c.start
    assert_equal [1002, 5, 6, 5, 99, 66], c.memory
  end

  def test_input
    c = Computer.new on_input: ->() { 100 }
    c.set_memory [3, 4, 99, 99, 99]

    c.start
    assert_equal [3, 4, 99, 99, 100], c.memory
  end
end