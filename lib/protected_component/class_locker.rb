class ProtectedComponent
  class ClassLocker
    attr_reader :component, :matcher

    def initialize(component:, matcher:)
      @component = component
      @matcher = matcher
    end

    def lock
      lock_instance_methods
      lock_class_methods
      # component.extend(ClassMethods)
    end

    private

    # module ClassMethods
    #   def method_added(name)
    #     lock_instance_method(method_name: name)
    #   end

    #   def singleton_method_added(name)
    #     lock_class_method(method_name: name)
    #   end
    # end

    def lock_instance_methods
      methods = component.instance_methods(false)
      methods.each do |method_name|
        lock_instance_method(method_name: method_name)
      end
    end

    def lock_class_methods
      methods = component.singleton_methods(false)
      methods.each do |method_name|
        lock_class_method(method_name: method_name)
      end
    end

    def lock_instance_method(method_name:)
      component.class_exec(method_name, matcher, component) do |name, matcher, component|
        original_method = component.instance_method(name)
        define_method(name) do |*args, &block|
          calling_class = binding.of_caller(1).eval("self.class")
          raise DirectCallNotAllowed unless matcher.match?(calling_class: calling_class)
          original_method.bind(self).call(*args, &block)
        end
      end
    end

    def lock_class_method(method_name:)
      component.class_exec(method_name, matcher, component) do |name, matcher, component|
        original_method = component.singleton_method(name)
        define_singleton_method(name) do |*args, &block|
          calling_class = binding.of_caller(1).eval("self")
          raise DirectCallNotAllowed unless matcher.match?(calling_class: calling_class)
          original_method.call(*args, &block)
        end
      end
    end
  end
end

# def self.included(receiving_class)
#   namespace_matcher = matcher.new(receiving_class: receiving_class)

#   methods = receiving_class.instance_methods(false) + receiving_class.private_instance_methods(false)
#   receiving_class.class_eval do
#     methods.each do |method_name|
#       original_method = instance_method(method_name)
#       define_method(method_name) do |*args, &block|
#         calling_class = binding.of_caller(1).eval("self.class")
#         raise DirectCallNotAllowed unless namespace_matcher.match?(calling_class: calling_class)
#         original_method.bind(self).call(*args, &block)
#       end
#     end
#   end
# end

# def self.extended(receiving_class)
#   namespace_matcher = matcher.new(receiving_class: receiving_class)

#   class_methods = receiving_class.singleton_methods(false)
#   receiving_class.class_eval do
#     class_methods.each do |method_name|
#       original_method = singleton_method(method_name)
#       define_singleton_method(method_name) do |*args, &block|
#         calling_class = binding.of_caller(1).eval("self")
#         raise DirectCallNotAllowed unless namespace_matcher.match?(calling_class: calling_class)
#         original_method.call(*args, &block)
#       end
#     end
#   end
# end
