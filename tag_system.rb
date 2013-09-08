TagRule = Struct.new(:first_character, :append_characters) do
  def applies_to?(string)
    string.chars.first == first_character
  end

  def follow(string)
    string + append_characters
  end
end

TagRulebook = Struct.new(:deletion_number, :rules) do
  def next_string(string)
    rule_for(string).follow(string).slice(deletion_number..-1)
  end

  def rule_for(string)
    rules.detect { |rule| rule.applies_to?(string) }
  end

  def applies_to?(string)
    !rule_for(string).nil? && string.length >= deletion_number
  end
end

TagSystem = Struct.new(:current_string, :rulebook) do
  def step
    self.current_string = rulebook.next_string(current_string)
  end

  def run
    while rulebook.applies_to?(current_string)
      puts current_string
      step
    end

    puts current_string
  end
end

rulebook = TagRulebook.new(2, [
  TagRule.new(?a, "cc"), TagRule.new(?b, "d"),
  TagRule.new(?c, "eo"), TagRule.new(?d, ""),
  TagRule.new(?e, "e")
])
system = TagSystem.new("aabbbbbbbbbb", rulebook)
system.run
