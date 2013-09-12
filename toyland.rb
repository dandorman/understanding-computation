Sign = Struct.new(:name) do
  NEGATIVE, ZERO, POSITIVE, UNKNOWN = [:negative, :zero, :positive, :unknown].map { |name| new(name) }

  def inspect
    "#<Sign #{name}>"
  end

  def *(other_sign)
    if [self, other_sign].include?(ZERO)
      ZERO
    elsif [self, other_sign].include?(UNKNOWN)
      UNKNOWN
    elsif self == other_sign
      POSITIVE
    else
      NEGATIVE
    end
  end

  def +(other_sign)
    if self == other_sign || other_sign == ZERO
      self
    elsif self == ZERO
      other_sign
    else
      UNKNOWN
    end
  end

  def <=(other_sign)
    self == other_sign || other_sign == UNKNOWN
  end
end

module SignedNumeric
  refine Numeric do
    def sign
      if self < 0
        Sign::NEGATIVE
      elsif zero?
        Sign::ZERO
      else
        Sign::POSITIVE
      end
    end
  end
end

using SignedNumeric

def sum_of_squares(x, y)
  (x * x) + (y * y)
end

inputs = Sign::NEGATIVE, Sign::ZERO, Sign::POSITIVE
outputs = inputs.product(inputs).map { |x, y| sum_of_squares(x, y) }
outputs.uniq
