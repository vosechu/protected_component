# frozen_string_literal: true

require "binding_of_caller"
require "protected_component/namespace_matcher"
require "protected_component/class_locker"

class ProtectedComponent
  DirectCallNotAllowed = Class.new(StandardError)

  def initialize(
    extra_callers: [],
    matcher_class: ProtectedComponent::NamespaceMatcher,
    locker_class: ProtectedComponent::ClassLocker
    )
    @extra_callers = extra_callers
    @matcher_class = matcher_class
    @locker_class = locker_class
  end

  def self.lock(**kwargs)
    new.lock(**kwargs)
  end

  def lock(component:)
    matcher = matcher_class.new(
      receiving_class: component,
      extra_callers: extra_callers
    )
    locker_class.new(
      component: component,
      matcher: matcher
    ).lock
  end

  private

  attr_reader :extra_callers, :matcher_class, :locker_class
end
