# frozen_string_literal: true

require "spec_helper"
require "protected_component"

# This is the main class/namespace structure we'll be testing
# Each other module/class is added in the contexts below
module Outer
  module Inner
    class TestInner
      def inner_method
        true
      end

      def self.inner_class_method
        true
      end
    end
    ProtectedComponent.lock(component: TestInner)
  end
end

module Outer
  module Inner
    RSpec.describe TestInner do
      it "allows instance method calls" do
        expect(subject.inner_method)
          .to be(true)
      end

      it "allows class method calls" do
        expect(described_class.inner_class_method)
          .to be(true)
      end
    end
  end
end

RSpec.describe ProtectedComponent do
  context "inner class calls from peers in the namespace" do
    before(:each) do
      # This class is a direct sibling of TestInner
      module Outer
        module Inner
          class TestPeer
            def inner_method
              TestInner.new.inner_method
            end

            def self.inner_class_method
              TestInner.inner_class_method
            end
          end
        end
      end
    end

    after(:each) do
      Outer::Inner.send(:remove_const, :TestPeer)
    end

    it "allows instance method calls" do
      expect(Outer::Inner::TestPeer.new.inner_method)
        .to be(true)
    end

    it "allows class method calls" do
      expect(Outer::Inner::TestPeer.inner_class_method)
        .to be(true)
    end
  end

  context "inner class calls from parent interface class" do
    before(:each) do
      # This class is an Aunt of TestInner, and would normally
      # be disallowed if its name was not InnerInterface
      module Outer
        class InnerInterface
          def inner_method
            Inner::TestInner.new.inner_method
          end

          def self.inner_class_method
            Inner::TestInner.inner_class_method
          end
        end
      end
    end

    after(:each) do
      Outer.send(:remove_const, :InnerInterface)
    end

    it "allows instance method calls" do
      expect(Outer::InnerInterface.new.inner_method)
        .to be(true)
    end

    it "allows class method calls" do
      expect(Outer::InnerInterface.inner_class_method)
        .to be(true)
    end
  end

  context "inner class calls from a parent namespace (but not the interface)" do
    before(:each) do
      # This class is an Aunt of TestInner and is not allowed
      # to directly access methods in the protected component
      module Outer
        class TestOuter
          def outer_method
            Inner::TestInner.new.inner_method
          end

          def self.outer_class_method
            Inner::TestInner.inner_class_method
          end
        end
      end
    end

    after(:each) do
      Outer.send(:remove_const, :TestOuter)
    end

    it "doesn't allow instance method calls" do
      expect { Outer::TestOuter.new.outer_method }
        .to raise_error(ProtectedComponent::DirectCallNotAllowed)
    end

    it "doesn't allow class method calls" do
      expect { Outer::TestOuter.outer_class_method }
        .to raise_error(ProtectedComponent::DirectCallNotAllowed)
    end
  end

  context "inner class calls from outside the namespace" do
    before(:each) do
      # This class is not closely related to TestInner and is
      # therefore not allow to make calls at all
      module OtherModule
        class OtherClass
          def other_method
            Outer::Inner::TestInner.new.inner_method
          end

          def self.other_class_method
            Outer::Inner::TestInner.inner_class_method
          end
        end
      end
    end

    after(:each) do
      OtherModule.send(:remove_const, :OtherClass)
      Object.send(:remove_const, :OtherModule)
    end

    it "doesn't allow instance method calls" do
      expect { OtherModule::OtherClass.new.other_method }
        .to raise_error(ProtectedComponent::DirectCallNotAllowed)
    end

    it "doesn't allow class method calls" do
      expect { OtherModule::OtherClass.other_class_method }
        .to raise_error(ProtectedComponent::DirectCallNotAllowed)
    end
  end

  xcontext "inner class calls added after the inner class is locked" do
    before(:each) do
      # This class is not closely related to TestInner and is
      # therefore not allow to make calls at all
      module OtherModule
        class OtherClass
          def other_method
            Outer::Inner::TestInner.new.new_inner_method
          end

          def self.other_class_method
            Outer::Inner::TestInner.new_inner_class_method
          end
        end
      end

      module Outer
        module Inner
          class TestInner
            def new_inner_method
              true
            end

            def self.new_inner_class_method
              true
            end
          end
        end
      end
    end

    after(:each) do
      OtherModule.send(:remove_const, :OtherClass)
      Object.send(:remove_const, :OtherModule)
      # Outer::Inner::TestInner.send(:remove_method, :new_inner_method)
      # Outer::Inner::TestInner.instance_eval("remove_method(:new_inner_class_method)")
    end

    it "doesn't allow instance method calls" do
      expect { OtherModule::OtherClass.new.other_method }
        .to raise_error(ProtectedComponent::DirectCallNotAllowed)
    end

    it "doesn't allow class method calls" do
      expect { OtherModule::OtherClass.other_class_method }
        .to raise_error(ProtectedComponent::DirectCallNotAllowed)
    end
  end
end
