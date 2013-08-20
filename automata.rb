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
