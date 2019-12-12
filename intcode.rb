require "pry"
require_relative "operations"

class Computer
  include OperationsFactory

  attr_accessor :ip, :memory, :halted

  def initialize(**options)
    @options = options
    @restart = :run_program
    @halted = false
  end

  def set_memory(memory)
    @memory = memory.dup
  end

  def start
    self.send(@restart)
  end

  def name
    @options[:name] || ''
  end

  private

  def run_program
    @ip = 0
    @halted = false
    continue_program
  end

  def continue_program
    raise if memory.nil?

    begin
      loop do
        puts "\n" << ("=" * 20)
        puts "#{name} starting loop..."
        puts "Instruction pointer: #{ip}"
        instruction = memory[ip]

        op_type = OperationsFactory::operation(instruction)
        op_params = memory.slice(@ip + 1, op_type.num_params)

        operation = OperationsFactory::create(instruction, op_params, @options)
        begin
          operation.apply(memory)
        rescue BlockingException
          # don't reset the instruction pointer
          @restart = :continue_program
          # but do end this method ----- but this moves the instruction pointer, so Input never completes!
          break
        ensure
          @ip = operation.advance_pointer_fn.call(@ip)
        end
      end
    rescue HaltException
      @halted = true
      @restart = :run_program
    end
  end
end

class HaltException < Exception
end

class BlockingException < Exception
end