class Operation
  # see http://www.railstips.org/blog/archives/2006/11/18/class-and-instance-variables-in-ruby/
  class << self
    attr_accessor :num_params
  end

  def initialize(inst, comp)
    @instruction = inst
    @computer = comp
  end

  def apply
    diag
  end

  def params
    @params ||= @computer.memory.slice(@computer.ip + 1, self.class.num_params)
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
      elsif val == 2
        :relative
      else
        raise "invalid parameter type"
      end
    end
  end

  def param_value(index)
    case param_types[index]
    when :immediate
      params[index]
    when :position
      read(params[index])
    when :relative
      address = @computer.relative_base + params[index]
      read(address)
    end
  end

  def diag
    # puts
    # puts "------ Instruction pointer: #{@computer.ip}"
    # puts "#{self.class.name} (#{@instruction}): #{params}"
  end

  def move_instruction_pointer_to(location)
    @computer.ip = location
  end

  def next_instruction_pointer
    @computer.ip + self.class.num_params + 1
  end

  def read(address)
    @computer.memory[address] ||= 0
  end

  def write(value:, address:)
    # puts "  -- writing #{value} to address #{address}"
    @computer.memory[address] = value
  end
end

module OperationsFactory

  def self.create(inst, comp)
    opcode = inst % 100
    OperationsFactory::operation(opcode).new(inst, comp)
  end

  class Add < Operation

    @num_params = 3

    def apply
      super

      addends = [0, 1].map { |i| param_value(i) }
      write_addr = if param_types[2] == :position
                     params[2]
                   elsif param_types[2] == :relative
                     params[2] + @computer.relative_base
                   end

      # (addends + [write_addr]).each_with_index do |p, i|
      #   puts "  param[#{i}]: #{param_types[i]} resolves to #{p}"
      # end

      write value: addends.sum, address: write_addr
      move_instruction_pointer_to next_instruction_pointer
    end
  end

  class Multiply < Operation

    @num_params = 3

    def apply
      super

      multiplicands = [0, 1].map { |i| param_value(i) }
      write_addr = if param_types[2] == :position
                     params[2]
                   elsif param_types[2] == :relative
                     params[2] + @computer.relative_base
                   end

      # (multiplicands + [write_addr]).each_with_index do |p, i|
      #   puts "  param[#{i}]: #{param_types[i]} resolves to #{p}"
      # end
      write value: multiplicands.reduce(&:*), address: write_addr
      move_instruction_pointer_to next_instruction_pointer
    end
  end

  class Halt < Operation

    @num_params = 0

    def apply
      super
      raise HaltException
    end
  end

  class Input < Operation

    @num_params = 1

    def apply
      super

      value = @computer.input_supplier.()
      write_addr = if param_types[0] == :position
                     params[0]
                   elsif param_types[0] == :relative
                     params[0] + @computer.relative_base
                   end

      # puts "  param[0]: #{param_types[0]} resolves to #{write_addr}"

      write value: value, address: write_addr
      move_instruction_pointer_to next_instruction_pointer
    end
  end

  class Output < Operation

    @num_params = 1

    def apply
      super

      value = param_value(0)
      @computer.output_consumer.(value)

      move_instruction_pointer_to next_instruction_pointer
    end
  end

  class JumpIfTrue < Operation

    @num_params = 2

    def apply
      super

      switch = param_value(0)
      next_ptr = if switch.zero?
                   next_instruction_pointer
                 else
                   param_value(1)
                 end

      # [switch, param_value(1)].each_with_index do |p, i|
      #   puts "  param[#{i}]: #{param_types[i]} resolves to #{p}"
      # end
      move_instruction_pointer_to next_ptr
    end
  end

  class JumpIfFalse < Operation

    @num_params = 2

    def apply
      super

      switch = param_value(0)
      next_ptr = if switch.zero?
                   param_value(1)
                 else
                   next_instruction_pointer
                 end

      # [switch, param_value(1)].each_with_index do |p, i|
      #   puts "  param[#{i}]: #{param_types[i]} resolves to #{p}"
      # end
      move_instruction_pointer_to next_ptr
    end
  end

  class LessThan < Operation

    @num_params = 3

    def apply
      super

      compare = [0, 1].map { |i| param_value(i) }
      write_addr = if param_types[2] == :position
                     params[2]
                   elsif param_types[2] == :relative
                     params[2] + @computer.relative_base
                   end

      # (compare + [write_addr]).each_with_index do |p, i|
      #   puts "  param[#{i}]: #{param_types[i]} resolves to #{p}"
      # end
      write value: compare[0] < compare[1] ? 1 : 0, address: write_addr
      move_instruction_pointer_to next_instruction_pointer
    end
  end

  class Equals < Operation

    @num_params = 3

    def apply
      super

      compare = [0, 1].map { |i| param_value(i) }
      write_addr = if param_types[2] == :position
                     params[2]
                   elsif param_types[2] == :relative
                     params[2] + @computer.relative_base
                   end


      # (compare + [write_addr]).each_with_index do |p, i|
      #   puts "  param[#{i}]: #{param_types[i]} resolves to #{p}"
      # end
      write value: compare[0] == compare[1] ? 1 : 0, address: write_addr
      move_instruction_pointer_to next_instruction_pointer
    end
  end

  class OffsetRelativeBase < Operation

    @num_params = 1

    def apply
      super

      value = param_value(0)
      @computer.relative_base += value

      # puts "  params[0]: #{param_types[0]} resolves to #{value}"
      # puts " -- relative base is now #{@computer.relative_base}"
      move_instruction_pointer_to next_instruction_pointer
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
    9 => OffsetRelativeBase,
    99 => Halt
  }
end
