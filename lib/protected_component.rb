require "binding_of_caller"

module ProtectedComponent
  DirectCallNotAllowed = Class.new(StandardError)

  def self.included(klass)
    methods = klass.instance_methods(false) + klass.private_instance_methods(false)
    klass.class_eval do
      methods.each do |method_name|
        original_method = instance_method(method_name)
        define_method(method_name) do |*args, &block|
          calling_class = binding.of_caller(1).eval("self.class")
          raise DirectCallNotAllowed unless namespaces_match(calling_class, klass)

          original_method.bind(self).call(*args, &block)
        end
      end
    end
  end

  def self.extended(klass)
    class_methods = klass.singleton_methods(false)
    klass.class_eval do
      class_methods.each do |method_name|
        original_method = singleton_method(method_name)
        define_singleton_method(method_name) do |*args, &block|
          calling_class = binding.of_caller(1).eval("self")
          raise DirectCallNotAllowed unless namespaces_match(calling_class, klass)

          original_method.call(*args, &block)
        end
      end
    end
  end

  private

  def namespaces_match(klass1, klass2)
    parent_namespace(klass1) == parent_namespace(klass2) ||
      klass1.to_s == parent_namespace(klass2) + "Interface"
  end

  # Stolen from Rails's `deconstantize`
  def parent_namespace(klass)
    klass.to_s.split("::")[0..-2].join("::")
  end
end
