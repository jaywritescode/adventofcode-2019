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
    c.set_memory [3, 3, 99, 99]

    c.start
    assert_equal [3, 3, 99, 100], c.memory
  end

  def test_output
    output = Minitest::Mock.new
    output.expect :dummy_method, nil, [42]

    c = Computer.new on_output: ->(x) { output.dummy_method(x) }
    c.set_memory [4, 3, 99, 42]

    c.start
    output.verify
  end

  def test_jump_if_true_is_actually_true
    c = Computer.new
    c.set_memory [1005, 4, 5, 0, 42, 99]

    c.start
    pass
  end

  def test_jump_if_true_but_is_actually_false
    c = Computer.new
    c.set_memory [1005, 4, 5, 99, 0, 42]

    c.start
    pass
  end

  def test_jump_if_false_is_actually_false
    c = Computer.new
    c.set_memory [1006, 4, 5, 42, 0, 99]

    c.start
    pass
  end

  def test_jump_if_false_but_is_actually_true
    c = Computer.new
    c.set_memory [1006, 4, 5, 99, 42, 0]

    c.start
    pass
  end

  def test_less_than_is_true
    c = Computer.new
    c.set_memory [1107, 9, 12, 5, 99, 100]

    c.start
    assert_equal [1107, 9, 12, 5, 99, 1], c.memory
  end

  def test_less_than_is_false
    c = Computer.new
    c.set_memory [1107, 12, 9, 5, 99, 100]

    c.start
    assert_equal [1107, 12, 9, 5, 99, 0], c.memory
  end

  def test_equals_is_true
    c = Computer.new
    c.set_memory [1108, 8, 8, 5, 99, 100]

    c.start
    assert_equal [1108, 8, 8, 5, 99, 1], c.memory
  end

  def test_equals_is_false
    c = Computer.new
    c.set_memory [1108, 8, 3, 5, 99, 100]

    c.start
    assert_equal [1108, 8, 3, 5, 99, 0], c.memory
  end
end
