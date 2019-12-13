require "pry"
require_relative "operations"

class Computer
  include OperationsFactory

  attr_accessor :ip, :memory, :halted

  def initialize(**options)
    @options = options
    @halted = false
    @current_operation = nil
  end

  def set_memory(memory)
    @memory = memory.dup
  end

  def name
    @options[:name] || ''
  end

  def current_operation
    @current_operation
  end

  def start
    raise if memory.nil?
    
    if current_operation.nil?
      @ip = 0
      @halted = false
    end

    run_program
  end

  def run_program
    begin
      loop do
        puts "\n" << ("=" * 20)

        if current_operation.nil?
          puts "#{name} starting loop..."
          puts "Instruction pointer: #{ip}"
          instruction = memory[ip]
  
          op_type = OperationsFactory::operation(instruction)
          op_params = memory.slice(@ip + 1, op_type.num_params)
  
          @current_operation = OperationsFactory::create(instruction, op_params, @options)
        else
          puts "#{name} resuming loop with instruction #{current_operation}"
        end

        begin
          current_operation.apply(memory)
          @ip = current_operation.next_instruction_pointer(@ip)
        rescue BlockingException
          break
        end

        @current_operation = nil
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