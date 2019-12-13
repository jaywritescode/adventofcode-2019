require "pry"
require_relative "operations"

class Computer
  include OperationsFactory

  attr_reader :input_supplier, :output_consumer
  attr_accessor :ip, :memory, :halted

  def initialize(**options)
    @options = options
    @halted = false
    @current_operation = nil

    @input_supplier = options[:on_input] || Proc.new { puts "Input: "; gets.to_i }
    @output_consumer = options[:on_output] || Proc.new { |value| puts value }
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
        if current_operation.nil?
          instruction = memory[ip]
          @current_operation = OperationsFactory::create(instruction, self)
        end

        begin
          current_operation.apply
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
