require "pry"
require_relative "operations"

class Computer
  include OperationsFactory

  attr_accessor :ip, :memory

  def initialize(**options)
    @ip = 0
    @outputs = []
    @options = options
  end

  def set_memory(memory)
    @memory = memory
  end

  def run_program
    raise if memory.nil?
    @outputs = []

    begin
      loop do
        puts "instruction pointer at: #{ip}"
        instruction = memory[ip]

        op_type = OperationsFactory::operation(instruction)
        op_params = memory.slice(@ip + 1, op_type.num_params)

        operation = OperationsFactory::create(instruction, op_params, options)

        begin
          operation.apply(memory)
        rescue OutputException => e
          @outputs << e.value
        ensure
          @ip = operation.advance_pointer_fn.call(@ip)
        end
      end
    rescue HaltException
      memory[0]
    end

    pp @outputs
    memory
  end
end

class HaltException < Exception
end

class OutputException < Exception
  attr_reader :value

  def initialize(val)
    @value = val
  end
end