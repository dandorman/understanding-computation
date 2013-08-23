require_relative 'automata'

module Pattern
  def bracket(outer_precedence)
    if precedence < outer_precedence
      ?( + to_s + ?)
    else
      to_s
    end
  end

  def inspect
    "/#{self}/"
  end

  def matches?(string)
    to_nfa_design.accepts?(string)
  end

  class Empty
    include Pattern

    def to_s
      ""
    end

    def precedence
      3
    end

    def to_nfa_design
      start_state = Object.new
      accept_states = [start_state]
      rulebook = NFARulebook.new([])

      NFADesign.new(start_state, accept_states, rulebook)
    end
  end

  Literal = Struct.new(:character) do
    include Pattern

    def to_s
      character
    end

    def precedence
      3
    end

    def to_nfa_design
      start_state = Object.new
      accept_state = Object.new
      rule = FARule.new(start_state, character, accept_state)
      rulebook = NFARulebook.new([rule])

      NFADesign.new(start_state, [accept_state], rulebook)
    end
  end

  Concatenate = Struct.new(:first, :second) do
    include Pattern

    def to_s
      [first, second].map { |pattern| pattern.bracket(precedence) }.join
    end

    def precedence
      1
    end

    def to_nfa_design
      first_nfa_design = first.to_nfa_design
      second_nfa_design = second.to_nfa_design

      start_state = first_nfa_design.start_state
      accept_states = second_nfa_design.accept_states
      rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules
      extra_rules = first_nfa_design.accept_states.map { |state|
        FARule.new(state, nil, second_nfa_design.start_state)
      }
      rulebook = NFARulebook.new(rules + extra_rules)

      NFADesign.new(start_state, accept_states, rulebook)
    end
  end

  Choose = Struct.new(:first, :second) do
    include Pattern

    def to_s
      [first, second].map { |pattern| pattern.bracket(precedence) }.join(?|)
    end

    def precedence
      0
    end

    def to_nfa_design
      first_nfa_design = first.to_nfa_design
      second_nfa_design = second.to_nfa_design

      start_state = Object.new
      accept_states = first_nfa_design.accept_states + second_nfa_design.accept_states
      rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules
      extra_rules = [first_nfa_design, second_nfa_design].map { |nfa_design|
        FARule.new(start_state, nil, nfa_design.start_state)
      }
      rulebook = NFARulebook.new(rules + extra_rules)

      NFADesign.new(start_state, accept_states, rulebook)
    end
  end

  Repeat = Struct.new(:pattern) do
    include Pattern

    def to_s
      pattern.bracket(precedence) + "*"
    end

    def precedence
      2
    end

    def to_nfa_design
      pattern_nfa_design = pattern.to_nfa_design

      start_state = Object.new
      accept_states = [start_state] + pattern_nfa_design.accept_states
      rules = pattern_nfa_design.rulebook.rules
      extra_rules = pattern_nfa_design.accept_states.map { |accept_state|
        FARule.new(accept_state, nil, pattern_nfa_design.start_state)
      } + [FARule.new(start_state, nil, pattern_nfa_design.start_state)]
      rulebook = NFARulebook.new(rules + extra_rules)

      NFADesign.new(start_state, accept_states, rulebook)
    end
  end

  # p pattern = Repeat.new(
  #   Choose.new(
  #     Concatenate.new(Literal.new(?a), Literal.new(?b)),
  #     Literal.new(?a)
  #   )
  # )

  # nfa_design = Empty.new.to_nfa_design
  # p nfa_design.accepts?("")
  # p nfa_design.accepts?(?a)

  # nfa_design = Literal.new(?a).to_nfa_design
  # p nfa_design.accepts?("")
  # p nfa_design.accepts?(?a)
  # p nfa_design.accepts?(?b)

  # p Empty.new.matches?(?a)
  # p Literal.new(?a).matches?(?a)

  # p pattern = Concatenate.new(
  #   Literal.new(?a),
  #   Concatenate.new(Literal.new(?b), Literal.new(?c))
  # )

  # p pattern.matches?("a")
  # p pattern.matches?("ab")
  # p pattern.matches?("abc")

  # p pattern = Choose.new(Literal.new(?a), Literal.new(?b))

  # p pattern.matches?(?a)
  # p pattern.matches?(?b)
  # p pattern.matches?(?c)

  # p pattern = Repeat.new(Literal.new(?a))

  # p pattern.matches?(?a * 0)
  # p pattern.matches?(?a * 1)
  # p pattern.matches?(?a * 4)
  # p pattern.matches?(?b * 1)

  # p pattern = Repeat.new(
  #   Concatenate.new(
  #     Literal.new(?a),
  #     Choose.new(Empty.new, Literal.new(?b))
  #   )
  # )

  # p pattern.matches?("")
  # p pattern.matches?("a")
  # p pattern.matches?("ab")
  # p pattern.matches?("aba")
  # p pattern.matches?("abab")
  # p pattern.matches?("abaab")
  # p pattern.matches?("abba")
end

require "treetop"
Treetop.load("pattern")

p parse_tree = PatternParser.new.parse("(a(|b))*")
p pattern = parse_tree.to_ast
p pattern.matches?("abaab")
p pattern.matches?("abba")
