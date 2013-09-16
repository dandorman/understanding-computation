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

  def type(context)
    Type::NUMBER
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

  def type(context)
    if left.type(context) == Type::NUMBER && right.type(context) == Type::NUMBER
      Type::NUMBER
    end
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

  def type(context)
    if left.type(context) == Type::NUMBER && right.type(context) == Type::NUMBER
      Type::NUMBER
    end
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

  def type(context)
    Type::BOOLEAN
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

  def type(context)
    if left.type(context) == Type::NUMBER && right.type(context) == Type::NUMBER
      Type::BOOLEAN
    end
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

  def type(context)
    context[name]
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

  def type(context)
    Type::VOID
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

  def type(context)
    if context[name] == expression.type(context)
      Type::VOID
    end
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

  def type(context)
    if condition.type(context) == Type::BOOLEAN &&
      consequence.type(context) == Type::VOID &&
      alternative.type(context) == Type::VOID

      Type::VOID
    end
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

  def type(context)
    if first.type(context) == Type::VOID && second.type(context) == Type::VOID
      Type::VOID
    end
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

  def type(context)
    if condition.type(context) == Type::BOOLEAN && body.type(context) == Type::VOID
      Type::VOID
    end
  end
end

Type = Struct.new(:name) do
  NUMBER, BOOLEAN, VOID = [:number, :boolean, :void].map { |name| new(name) }

  def inspect
    "#<Type #{name}>"
  end
end

statement = Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)))
statement.type(x: Type::NUMBER)
statement.evaluate({})
