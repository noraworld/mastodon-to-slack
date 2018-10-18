# frozen_string_literal: true

# booleanize string with 'true' or 'false'
class String
  def booleanize
    if self == 'true'
      true
    elsif self == 'false'
      false
    else
      raise StandardError, "can't booleanize `#{self}' because it is neither 'true' nor 'false'"
    end
  end
end
