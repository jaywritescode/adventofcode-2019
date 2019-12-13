class Operation
  # see http://www.railstips.org/blog/archives/2006/11/18/class-and-instance-variables-in-ruby/
  class << self
    attr_accessor :num_params
  end

  def initialize(inst, params)
    @instruction = inst
    @params = params
  end

  def apply(mem)
    diag
  end

  def param_types
    return @param_types unless @param_types.nil?

    return [] if self.class.num_params.zero?

    s = "%0#{self.class.num_params + 2}d" % @instruction
    @param_types = s.chars[0...-2].reverse.map(&:to_i).map do |val|
      if val == 0
        :position
      elsif val == 1
        :immediate
      else
        raise "invalid parameter type"
      end
    end
  end

  def param_value(mem, index)
    param_types[index] == :immediate ? @params[index] : mem[@params[index]]
  end

  def diag
  end

  def next_instruction_pointer(ip)
    ip + self.class.num_params + 1
  end
end

module OperationsFactory

  def self.create(inst, params, **options)
    opcode = inst % 100
    OperationsFactory::operation(opcode).new(inst, params, **options)
  end

  class Add < Operation

    @num_params = 3

    def apply(mem)
      super
      addends = [0, 1].map { |i| param_value(mem, i) }
      write_addr = @params[2]
      mem[write_addr] = addends.sum
    end
  end

  class Multiply < Operation

    @num_params = 3

    def apply(mem)
      super
      multiplicands = [0, 1].map { |i| param_value(mem, i) }
      write_addr = @params[2]
      mem[write_addr] = multiplicands.reduce(&:*)
    end
  end

  class Halt < Operation

    @num_params = 0

    def apply(mem)
      super
      raise HaltException
    end
  end

  class Input < Operation

    @num_params = 1

    def initialize(inst, params, **options)
      super
      @input = options[:on_input] || Proc.new { puts "Input: "; gets.to_i }
    end

    def apply(mem)
      super
      value = @input.()
      write_addr = @params[0]
      mem[write_addr] = value
    end
  end

  class Output < Operation

    @num_params = 1

    def initialize(inst, params, **options)
      super
      @output = options[:on_output] || Proc.new { |value| puts value }
    end

    def apply(mem)
      super
      value = param_value(mem, 0)
      @output.(value)
    end
  end

  class JumpIfTrue < Operation

    @num_params = 2

    def initialize(inst, params, **options)
      super
      @do_jump = nil
    end

    def apply(mem)
      super

      unless param_value(mem, 0).zero?
        @do_jump = param_value(mem, 1)
      end
    end

    def next_instruction_pointer(ip)
      if @do_jump
        @do_jump
      else
        super
      end
    end
  end

  class JumpIfFalse < Operation

    @num_params = 2

    def initialize(inst, params, **options)
      super
      @do_jump = nil
    end

    def apply(mem)
      super
      
      if param_value(mem, 0).zero?
        @do_jump = param_value(mem, 1)
      end
    end

    def next_instruction_pointer(ip)
      if @do_jump
        @do_jump
      else
        super
      end
    end
  end

  class LessThan < Operation

    @num_params = 3

    def apply(mem)
      super
      compare = [0, 1].map { |i| param_value(@params, i) }
      write_addr = @params[2]

      mem[write_addr] = compare[0] < compare[1] ? 1 : 0
    end
  end

  class Equals < Operation

    @num_params = 3

    def apply(mem)
      super
      compare = [0, 1].map { |i| param_value(mem, i) }
      write_addr = @params[2]

      mem[write_addr] = compare[0] == compare[1] ? 1 : 0
    end
  end

  class Noop < Operation
    
    @num_params = -1

    def apply(mem)
      super
    end
  end

  def self.operation(opcode)
    binding.pry if opcode.nil?
    @@OPERATIONS.fetch(opcode % 100)
  end

  @@OPERATIONS = {
    0 => Noop,
    1 => Add,
    2 => Multiply,
    3 => Input,
    4 => Output,
    5 => JumpIfTrue,
    6 => JumpIfFalse,
    7 => LessThan,
    8 => Equals,
    99 => Halt
  }
end