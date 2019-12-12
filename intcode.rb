require "pry"
require_relative "operations"

class Computer
  include OperationsFactory

  attr_accessor :ip, :memory, :halted

  def initialize(**options)
    @options = options
    @halted = false
    @current_instruction = nil
  end

  def set_memory(memory)
    @memory = memory.dup
  end

  def name
    @options[:name] || ''
  end

  def current_instruction
    @current_instruction
  end

  def start
    raise if memory.nil?
    
    # you might need to move these again
    @ip = 0
    @halted = false

    run_program
  end

  def run_program
    begin
      loop do
        if current_instruction.nil?
          puts "\n" << ("=" * 20)
          puts "#{name} starting loop..."
          puts "Instruction pointer: #{ip}"
          instruction = memory[ip]
  
          op_type = OperationsFactory::operation(instruction)
          op_params = memory.slice(@ip + 1, op_type.num_params)
  
          operation = OperationsFactory::create(instruction, op_params, @options)
  
          @current_instruction = operation
        end

        begin
          operation.apply(memory)
          @ip = operation.next_instruction_pointer(@ip)
        rescue BlockingException
          break
        end

        @current_instruction = nil
      end
    rescue HaltException
      @halted = true
    end
  end
end

class HaltException < Exception
end

class BlockingException < Exception
end