require "pry"
require_relative "operations"

class Computer
  include OperationsFactory

  attr_accessor :ip, :memory

  def initialize(**options)
    @options = options
    @restart = :run_program
  end

  def set_memory(memory)
    @memory = memory
  end

  def start
    self.send(@restart)
  end

  private

  def run_program
    @ip = 0
    continue_program
  end

  def continue_program
    raise if memory.nil?

    begin
      loop do
        puts "instruction pointer at: #{ip}"
        instruction = memory[ip]

        op_type = OperationsFactory::operation(instruction)
        op_params = memory.slice(@ip + 1, op_type.num_params)

        operation = OperationsFactory::create(instruction, op_params, @options)
        begin
          operation.apply(memory)
        rescue BlockingException
          # don't reset the instruction pointer
          @restart = :continue_program
          # but do end this method
          break
        ensure
          @ip = operation.advance_pointer_fn.call(@ip)
        end
      end
    rescue HaltException
      memory[0]
    end

    @outputs
  end
end

class HaltException < Exception
end

class BlockingException < Exception
end