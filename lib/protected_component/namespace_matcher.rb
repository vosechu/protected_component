# frozen_string_literal: true

class ProtectedComponent
  class NamespaceMatcher
    attr_reader :receiving_class, :extra_callers

    def initialize(receiving_class:, extra_callers: [])
      @receiving_class = receiving_class
      @extra_callers = []
    end

    def match?(calling_class:)
      # require 'pry'; binding.pry; 1
      parent_namespace(calling_class) == parent_namespace(receiving_class) ||
        allowed_callers.include?(calling_class.to_s) ||
        allowed_callers.include?(calling_class.class.to_s)
    end

    def allowed_callers
      [
        parent_namespace(receiving_class),
        parent_namespace(receiving_class) + "Interface",
        *extra_callers,
        "RSpec::ExampleGroups::#{receiving_class.to_s.gsub("::", '')}"
      ]
    end

    private

    # Similar to Rails's `deconstantize`
    def parent_namespace(klass)
      klass.to_s.split("::")[0..-2].join("::")
    end
  end
end
