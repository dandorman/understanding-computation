require "treetop"
require_relative "simple"

Treetop.load("simple")

p parse_tree = SimpleParser.new.parse("while (x < 5) { x = x * 3 }")
p statement = parse_tree.to_ast
p statement.evaluate(x: Number.new(1))
p statement.to_ruby
