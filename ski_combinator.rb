SKISymbol = Struct.new(:name) do
  def to_s
    name.to_s
  end
  alias_method :inspect, :to_s

  def combinator
    self
  end

  def arguments
    []
  end

  def callable?(*arguments)
    false
  end

  def reducible?
    false
  end

  def as_a_function_of(name)
    if self.name == name
      I
    else
      SKICall.new(K, self)
    end
  end

  def to_iota
    self
  end
end

SKICall = Struct.new(:left, :right) do
  def to_s
    "#{left}[#{right}]"
  end
  alias_method :inspect, :to_s

  def combinator
    left.combinator
  end

  def arguments
    left.arguments + [right]
  end

  def reducible?
    left.reducible? || right.reducible? || combinator.callable?(*arguments)
  end

  def reduce
    if left.reducible?
      SKICall.new(left.reduce, right)
    elsif right.reducible?
      SKICall.new(left, right.reduce)
    else
      combinator.call(*arguments)
    end
  end

  def as_a_function_of(name)
    left_function = left.as_a_function_of(name)
    right_function = right.as_a_function_of(name)

    SKICall.new(SKICall.new(S, left_function), right_function)
  end

  def to_iota
    SKICall.new(left.to_iota, right.to_iota)
  end
end

class SKICombinator < SKISymbol
  def callable?(*arguments)
    arguments.length == method(:call).arity
  end

  def as_a_function_of(name)
    SKICall.new(K, self)
  end
end

S, K, I = [:S, :K, :I].map { |name| SKICombinator.new(name) }

def S.call(a, b, c)
  SKICall.new(SKICall.new(a, c), SKICall.new(b, c))
end

def S.to_iota
  SKICall.new(IOTA, SKICall.new(IOTA, SKICall.new(IOTA, SKICall.new(IOTA, IOTA))))
end

def K.call(a, b)
  a
end

def K.to_iota
  SKICall.new(IOTA, SKICall.new(IOTA, SKICall.new(IOTA, IOTA)))
end

def I.call(a)
  a
end

def I.to_iota
  SKICall.new(IOTA, IOTA)
end

IOTA = SKICombinator.new("ι")

def IOTA.call(a)
  SKICall.new(SKICall.new(a, S), K)
end

require_relative "lambda"

class LCVariable
  def to_ski
    SKISymbol.new(name)
  end
end

class LCCall
  def to_ski
    SKICall.new(left.to_ski, right.to_ski)
  end
end

class LCFunction
  def to_ski
    body.to_ski.as_a_function_of(parameter)
  end
end

require "treetop"
Treetop.load("lambda")

two = LambdaCalculusParser.new.parse("-> p { -> x { p[p[x]] } }").to_ast
p two.to_ski.to_iota
inc, zero = SKISymbol.new(:inc), SKISymbol.new(:zero)
expression = SKICall.new(SKICall.new(two.to_ski.to_iota, inc), zero)
expression = expression.reduce while expression.reducible?
p expression
