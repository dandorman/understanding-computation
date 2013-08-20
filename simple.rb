Machine = Struct.new(:statement, :environment) do
  def step
    self.statement, self.environment = statement.reduce(environment)
  end

  def run
    while statement.reducible?
      puts "#{statement}, #{environment}"
      step
    end
    puts "#{statement}, #{environment}"
  end
end

Number = Struct.new(:value) do
  def reducible?
    false
  end

  def evaluate(environment)
    self
  end

  def to_ruby
    "-> e { #{value.inspect} }"
  end

  def to_s
    value.to_s
  end

  def inspect
    "«#{self}»"
  end
end

Add = Struct.new(:left, :right) do
  def reducible?
    true
  end

  def reduce(environment)
    if left.reducible?
      self.class.new(left.reduce(environment), right)
    elsif right.reducible?
      self.class.new(left, right.reduce(environment))
    else
      Number.new(left.value + right.value)
    end
  end

  def evaluate(environment)
    Number.new(left.evaluate(environment).value + right.evaluate(environment).value)
  end

  def to_ruby
    "-> e { (#{left.to_ruby}).call(e) + (#{right.to_ruby}).call(e) }"
  end

  def to_s
    "#{left} + #{right}"
  end

  def inspect
    "«#{self}»"
  end
end

Multiply = Struct.new(:left, :right) do
  def reducible?
    true
  end

  def reduce(environment)
    if left.reducible?
      self.class.new(left.reduce(environment), right)
    elsif right.reducible?
      self.class.new(left, right.reduce(environment))
    else
      Number.new(left.value * right.value)
    end
  end

  def evaluate(environment)
    Number.new(left.evaluate(environment).value * right.evaluate(environment).value)
  end

  def to_ruby
    "-> e { (#{left.to_ruby}).call(e) * (#{right.to_ruby}).call(e) }"
  end

  def to_s
    "#{left} * #{right}"
  end

  def inspect
    "«#{self}»"
  end
end

Boolean = Struct.new(:value) do
  def reducible?
    false
  end

  def evaluate(environment)
    self
  end

  def to_ruby
    "-> e { #{value.inspect} }"
  end

  def to_s
    value.to_s
  end

  def inspect
    "«#{self}»"
  end
end

LessThan = Struct.new(:left, :right) do
  def reducible?
    true
  end

  def reduce(environment)
    if left.reducible?
      self.class.new(left.reduce(environment), right)
    elsif right.reducible?
      self.class.new(left, right.reduce(environment))
    else
      Boolean.new(left.value < right.value)
    end
  end

  def evaluate(environment)
    Boolean.new(left.evaluate(environment).value < right.evaluate(environment).value)
  end

  def to_ruby
    "-> e { (#{left.to_ruby}).call(e) < (#{right.to_ruby}).call(e) }"
  end

  def to_s
    "#{left} < #{right}"
  end

  def inspect
    "«#{self}»"
  end
end

Variable = Struct.new(:name) do
  def reducible?
    true
  end

  def reduce(environment)
    environment.fetch(name)
  end

  def evaluate(environment)
    environment.fetch(name)
  end

  def to_ruby
    "-> e { e.fetch(#{name.inspect}) }"
  end

  def to_s
    name.to_s
  end

  def inspect
    "«#{self}»"
  end
end

class DoNothing
  def reducible?
    false
  end

  def evaluate(environment)
    environment
  end

  def to_ruby
    "-> e { e }"
  end

  def to_s
    "do-nothing"
  end

  def inspect
    "«#{self}»"
  end

  def ==(other_statement)
    other_statement.instance_of?(DoNothing)
  end
end

Assign = Struct.new(:name, :expression) do
  def reducible?
    true
  end

  def reduce(environment)
    if expression.reducible?
      [self.class.new(name, expression.reduce(environment)), environment]
    else
      [DoNothing.new, environment.merge(name => expression)]
    end
  end

  def evaluate(environment)
    environment.merge(name => expression.evaluate(environment))
  end

  def to_ruby
    "-> e { e.merge({ #{name.inspect} => (#{expression.to_ruby}).call(e) }) }"
  end

  def to_s
    "#{name} = #{expression}"
  end

  def inspect
    "«#{self}»"
  end
end

If = Struct.new(:condition, :consequence, :alternative) do
  def reducible?
    true
  end

  def reduce(environment)
    if condition.reducible?
      [self.class.new(condition.reduce(environment), consequence, alternative), environment]
    else
      case condition
      when Boolean.new(true)
        [consequence, environment]
      when Boolean.new(false)
        [alternative, environment]
      end
    end
  end

  def evaluate(environment)
    case condition.evaluate(environment)
    when Boolean.new(true)
      consequence.evaluate(environment)
    when Boolean.new(false)
      alternative.evaluate(environment)
    end
  end

  def to_ruby
    "-> e { if (#{condition.to_ruby}).call(e) " \
      "then (#{consequence.to_ruby}).call(e) "  \
      "else (#{alternative.to_ruby}).call(e) "  \
      "end }"
  end

  def to_s
    "if (#{condition}) { #{consequence} } else { #{alternative} }"
  end

  def inspect
    "«#{self}»"
  end
end

Sequence = Struct.new(:first, :second) do
  def reducible?
    true
  end

  def reduce(environment)
    case first
    when DoNothing
      [second, environment]
    else
      reduced_first, reduced_environment = first.reduce(environment)
      [self.class.new(reduced_first, second), reduced_environment]
    end
  end

  def evaluate(environment)
    second.evaluate(first.evaluate(environment))
  end

  def to_ruby
    "-> e { (#{second.to_ruby}).call((#{first.to_ruby}).call(e)) }"
  end

  def to_s
    "#{first}; #{second}"
  end

  def inspect
    "«#{self}»"
  end
end

While = Struct.new(:condition, :body) do
  def reducible?
    true
  end

  def reduce(environment)
    [If.new(condition, Sequence.new(body, self), DoNothing.new), environment]
  end

  def evaluate(environment)
    case condition.evaluate(environment)
    when Boolean.new(true)
      evaluate(body.evaluate(environment))
    when Boolean.new(false)
      environment
    end
  end

  def to_ruby
    "-> e { " \
      "while (#{condition.to_ruby}).call(e); e = (#{body.to_ruby}).call(e); end; " \
      "e " \
      "}"
  end

  def to_s
    "while (#{condition}) { #{body} }"
  end

  def inspect
    "«#{self}»"
  end
end

# Machine.new(
#   Add.new(Multiply.new(Number.new(1), Number.new(2)),
#           Multiply.new(Number.new(3), Number.new(4)))
# ).run

# Machine.new(
#   LessThan.new(Number.new(5), Add.new(Number.new(2), Number.new(2)))
# ).run

# Machine.new(
#   Add.new(Variable.new(:x), Variable.new(:y)),
#   { x: Number.new(3), y: Number.new(4) }
# ).run

# Machine.new(
#   Assign.new(:x, Add.new(Variable.new(:x), Number.new(1))),
#   { x: Number.new(2) }
# ).run

# Machine.new(
#   If.new(
#     Variable.new(:x),
#     Assign.new(:y, Number.new(1)),
#     Assign.new(:y, Number.new(2))
#   ),
#   { x: Boolean.new(true) }
# ).run

# Machine.new(
#   If.new(
#     Variable.new(:x),
#     Assign.new(:y, Number.new(1)),
#     DoNothing.new
#   ),
#   { x: Boolean.new(false) }
# ).run

# Machine.new(
#   Sequence.new(
#     Assign.new(:x, Add.new(Number.new(1), Number.new(1))),
#     Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))
#   ),
#   {}
# ).run

# Machine.new(
#   While.new(
#     LessThan.new(Variable.new(:x), Number.new(5)),
#     Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
#   ),
#   { x: Number.new(1) }
# ).run

# p Number.new(23).evaluate({})
# p Variable.new(:x).evaluate({ x: Number.new(23) })
# p LessThan.new(
#   Add.new(Variable.new(:x), Number.new(2)),
#   Variable.new(:y)
# ).evaluate(x: Number.new(2), y: Number.new(5))

# p statement = Sequence.new(
#   Assign.new(:x, Add.new(Number.new(1), Number.new(1))),
#   Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))
# )
# p statement.evaluate({})

# p statement = While.new(
#   LessThan.new(Variable.new(:x), Number.new(5)),
#   Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
# )
# p statement.evaluate(x: Number.new(1))

# p Number.new(5).to_ruby
# p Boolean.new(false).to_ruby

# p eval(Number.new(5).to_ruby).call({})
# p eval(Boolean.new(false).to_ruby).call({})

# p expression = Variable.new(:x)
# p eval(p expression.to_ruby).call(x: 7)

# p Add.new(Variable.new(:x), Number.new(1)).to_ruby
# p LessThan.new(Add.new(Variable.new(:x), Number.new(1)), Number.new(3)).to_ruby

# environment = { x: 3 }
# p eval(p Add.new(Variable.new(:x), Number.new(1)).to_ruby).call(environment)
# p eval(p LessThan.new(Add.new(Variable.new(:x), Number.new(1)), Number.new(3)).to_ruby).call(environment)

# p statement = Assign.new(:y, Add.new(Variable.new(:x), Number.new(1)))
# p eval(p statement.to_ruby).call(x: 3)

p statement = While.new(
  LessThan.new(Variable.new(:x), Number.new(5)),
  Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
)
p eval(p statement.to_ruby).call(x: 1)
