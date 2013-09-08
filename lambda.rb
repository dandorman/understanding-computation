LCVariable = Struct.new(:name) do
  def to_s
    name.to_s
  end
  alias_method :inspect, :to_s

  def replace(name, replacement)
    self.name == name ? replacement : self
  end

  def callable?
    false
  end

  def reducible?
    false
  end
end

LCFunction = Struct.new(:parameter, :body) do
  def to_s
    "-> #{parameter} { #{body} }"
  end
  alias_method :inspect, :to_s

  def replace(name, replacement)
    if parameter == name
      self
    else
      self.class.new(parameter, body.replace(name, replacement))
    end
  end

  def callable?
    true
  end

  def call(argument)
    body.replace(parameter, argument)
  end

  def reducible?
    false
  end
end

LCCall = Struct.new(:left, :right) do
  def to_s
    "#{left}[#{right}]"
  end
  alias_method :inspect, :to_s

  def replace(name, replacement)
    self.class.new(left.replace(name, replacement), right.replace(name, replacement))
  end

  def callable?
    false
  end

  def reducible?
    left.reducible? || right.reducible? || left.callable?
  end

  def reduce
    if left.reducible?
      self.class.new(left.reduce, right)
    elsif right.reducible?
      self.class.new(left, right.reduce)
    else
      left.call(right)
    end
  end
end

# one =
#   LCFunction.new(
#     :p,
#     LCFunction.new(
#       :x,
#       LCCall.new(LCVariable.new(:p), LCVariable.new(:x))
#     )
# )

# increment =
#   LCFunction.new(
#     :n,
#     LCFunction.new(
#       :p,
#       LCFunction.new(
#         :x,
#         LCCall.new(
#           LCVariable.new(:p),
#           LCCall.new(
#             LCCall.new(LCVariable.new(:n), LCVariable.new(:p)),
#             LCVariable.new(:x)
#           )
#         )
#       )
#     )
# )

# add =
#   LCFunction.new(
#     :m,
#     LCFunction.new(
#       :n,
#       LCCall.new(LCCall.new(LCVariable.new(:n), increment), LCVariable.new(:m))
#     )
# )

# inc, zero = LCVariable.new(:inc), LCVariable.new(:zero)

# expression = LCCall.new(LCCall.new(add, one), one)
# while expression.reducible?
#   expression
#   expression = expression.reduce
# end
# expression

# expression = LCCall.new(LCCall.new(expression, inc), zero)
# while expression.reducible?
#   p expression
#   expression = expression.reduce
# end
# p expression

# require "treetop"
# Treetop.load("lambda")
# parse_tree = LambdaCalculusParser.new.parse("-> x { x[x] }[-> y { y }]")
# expression = parse_tree.to_ast
# expression.reduce
