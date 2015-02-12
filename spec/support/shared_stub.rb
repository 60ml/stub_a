require 'stub_a'

shared_context "shared stub" do
  let(:stub) do
    StubA.new target
  end

  let(:hook_method_name) do
    ->(method, type) { stub.__send__ :hook_method_name, method, type }
  end

  [:first,
   :second,
   :third,
   :zweit,
   :dritt,
  ].product(
    [:origin,
     :before,
     :after,
     :stub,
    ]).each do |(method, type)|
    let("#{type}_#{method}_method_name") do
      hook_method_name.call(method, type)
    end
  end

  class Foo
    def initialize(log)
      @log = log
    end

    def first
      @log.push(:origin)
      @log
    end

    def second(a, b)
      @log.push(:origin)
      @log.push([a, b])
      @log
    end

    def third(a, b)
      @log.push(:origin)
      yield(@log, a, b)
      @log
    end

    class << self
      def zweit(log, a, b)
        log.push(:origin)
        log.push([a, b])
        log
      end

      def dritt(log, a, b)
        log.push(:origin)
        yield(log, a, b)
        log
      end
    end
  end
end
