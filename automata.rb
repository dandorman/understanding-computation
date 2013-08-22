FARule = Struct.new(:state, :character, :next_state) do
  def applies_to?(state, character)
    self.state == state && self.character == character
  end

  def follow
    next_state
  end

  def inspect
    "#<#{self.class.name} #{state.inspect} --#{character}--> #{next_state.inspect}>"
  end
end

DFARulebook = Struct.new(:rules) do
  def next_state(state, character)
    rule_for(state, character).follow
  end

  def rule_for(state, character)
    rules.detect { |rule| rule.applies_to?(state, character) }
  end
end

DFA = Struct.new(:current_state, :accept_states, :rulebook) do
  def accepting?
    accept_states.include?(current_state)
  end

  def read_character(character)
    self.current_state = rulebook.next_state(current_state, character)
  end

  def read_string(string)
    string.chars do |character|
      read_character(character)
    end
  end
end

DFADesign = Struct.new(:start_state, :accept_states, :rulebook) do
  def to_dfa
    DFA.new(start_state, accept_states, rulebook)
  end

  def accepts?(string)
    to_dfa.tap { |dfa| dfa.read_string(string) }.accepting?
  end
end

require 'set'

NFARulebook = Struct.new(:rules) do
  def next_states(states, character)
    states.flat_map { |state| follow_rules_for(state, character) }.to_set
  end

  def follow_rules_for(state, character)
    rules_for(state, character).map(&:follow)
  end

  def rules_for(state, character)
    rules.select { |rule| rule.applies_to?(state, character) }
  end

  def follow_free_moves(states)
    more_states = next_states(states, nil)

    if more_states.subset?(states)
      states
    else
      follow_free_moves(states + more_states)
    end
  end
end

class NFA < Struct.new(:current_states, :accept_states, :rulebook)
  def accepting?
    (current_states & accept_states).any?
  end

  def read_character(character)
    self.current_states = rulebook.next_states(current_states, character)
  end

  def read_string(string)
    string.chars do |character|
      read_character(character)
    end
  end

  def current_states
    rulebook.follow_free_moves(super)
  end
end

NFADesign = Struct.new(:start_state, :accept_states, :rulebook) do
  def to_nfa
    NFA.new(Set[start_state], accept_states, rulebook)
  end

  def accepts?(string)
    to_nfa.tap { |nfa| nfa.read_string(string) }.accepting?
  end
end

# rulebook = DFARulebook.new([
#   FARule.new(1, ?a, 2), FARule.new(1, ?b, 1),
#   FARule.new(2, ?a, 2), FARule.new(2, ?b, 3),
#   FARule.new(3, ?a, 3), FARule.new(3, ?b, 3),
# ])
# p rulebook.next_state(1, ?a)
# p rulebook.next_state(1, ?b)
# p rulebook.next_state(2, ?b)

# dfa = DFA.new(1, [3], rulebook); p dfa.accepting?
# dfa.read_character(?b); p dfa.accepting?
# 3.times do dfa.read_character(?a) end; p dfa.accepting?
# dfa.read_character(?b); p dfa.accepting?
# dfa.read_string("baaab"); p dfa.accepting?

# dfa_design = DFADesign.new(1, [3], rulebook)
# p dfa_design.accepts?("a")
# p dfa_design.accepts?("baa")
# p dfa_design.accepts?("baba")

# rulebook = NFARulebook.new([
#   FARule.new(1, ?a, 1), FARule.new(1, ?b, 1), FARule.new(1, ?b, 2),
#   FARule.new(2, ?a, 3), FARule.new(2, ?b, 3),
#   FARule.new(3, ?a, 4), FARule.new(3, ?b, 4)
# ])
# p rulebook.next_states(Set[1], ?b)
# p rulebook.next_states(Set[1, 2], ?a)
# p rulebook.next_states(Set[1, 3], ?b)

# p NFA.new(Set[1], [4], rulebook).accepting?
# p NFA.new(Set[1, 2, 4], [4], rulebook).accepting?
# nfa = NFA.new(Set[1], [4], rulebook); p nfa.accepting?
# nfa.read_character(?b); p nfa.accepting?
# nfa.read_character(?a); p nfa.accepting?
# nfa.read_character(?b); p nfa.accepting?

# nfa = NFA.new(Set[1], [4], rulebook); p nfa.accepting?
# nfa.read_string(?b * 5); p nfa.accepting?

# nfa_design = NFADesign.new(1, [4], rulebook)
# p nfa_design.accepts?("bab")
# p nfa_design.accepts?("bbbbb")
# p nfa_design.accepts?("bbabb")

rulebook = NFARulebook.new([
  FARule.new(1, nil, 2), FARule.new(1, nil, 4),
  FARule.new(2, ?a, 3),
  FARule.new(3, ?a, 2),
  FARule.new(4, ?a, 5),
  FARule.new(5, ?a, 6),
  FARule.new(6, ?a, 4)
])

# p rulebook.next_states(Set[1], nil)

nfa_design = NFADesign.new(1, [2, 4], rulebook)
p nfa_design.accepts?(?a * 2)
p nfa_design.accepts?(?a * 3)
p nfa_design.accepts?(?a * 5)
p nfa_design.accepts?(?a * 6)
