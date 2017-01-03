require 'better_assert_difference/version'

module BetterAssertDifference
  DEFAULT_DIFF = 1

  def assert_difference(expression, difference = DEFAULT_DIFF, message = nil, &block)
    expression_to_diff =
      if expression.is_a?(Hash)
        expression
      else
        Array(expression).each_with_object({}) { |exp, expression_hash| expression_hash[exp] = DEFAULT_DIFF }
      end
    block_to_diff =
      expression_to_diff.each_with_object({}) do |(exp, diff), expression_hash|
        key =
          if exp.respond_to?(:call)
            exp
          elsif exp.respond_to?(:count) && !exp.is_a?(String)
            -> { exp.count }
          else
            -> { eval(exp, block.binding) }
          end
        expression_hash[key] = diff
      end
    before = block_to_diff.keys.map(&:call)
    retval = yield
    after = block_to_diff.keys.map(&:call)

    errors = []
    before.zip(after, expression_to_diff) do |before_value, after_value, (exp, diff)|
      next if before_value + diff == after_value
      error  = "#{exp.inspect} didn't change by #{diff}"
      error  = "#{message}.\n#{error}" if message
      errors << error
    end
    fail errors.join("\n") if errors.any?

    retval
  end
end
