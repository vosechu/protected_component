# Protected Component

Weak component boundaries are the cause of so many problems in OO programming. Wouldn't it be nice if you had a direct way of informing people that they're reaching into your component in a dangerous way? That's what this project will do.

## Usage

TODO: Wrap this up into a gem and add instructions about how to call it in your Gemfile.

Add this code to the bottom of any of your namespaced classes:

```
include ProtectedComponent
extend  ProtectedComponent
```

For example:

```
module Payments
  module MonthlyEstimation
    class Estimator
      def calculate(**kwargs)
      ...
      end

      include ProtectedComponent
      extend  ProtectedComponent
    end
  end
end
```

Once ProtectedComponent is included, only two types of classes will be able to talk to it:

1. Peers inside the `MonthlyEstimation` namespace
2. A single class inside `Payments` called `MonthlyEstimationInterface`.

Any other classes will get a `ProtectedComponent::DirectCallNotAllowed` exception raised immediately.

## What's the point?

* Components with strong interfaces allow us to move them around very easily, change their names, and even change how they work.
* Components with _small_ interfaces allow us to easily find their usages in our code and reason about how and where we move them to.

## How do I know where to draw my component boundaries?

That's a matter for books, but my rules of thumb are these:

1. Wrap a module around one important "action" or "artifact" that your system creates and name it for the verb.
  - `MonthlyEstimation` is a distinct thing that we do, but `Estimators` would be a "component collection" rather than a distinct component.
2. Think about what this thing would feel like if it were a remote API (even if it's probably not worth it). Ignoring how _it_ fetches data, does it make sense on its own? Or does it only have value when run through some other bit of code (like an EstimationReportGenerator).
  - When you think of how it'll be used, are there any other classes that help it make sense? Formatters, generators, processors, etc. Those might like to live in the namespace too, even if they're copied from elsewhere.
