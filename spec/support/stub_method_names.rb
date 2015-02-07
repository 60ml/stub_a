require 'stub_a'

shared_context "shared stub" do
  let(:stub) do
    StubA.new *(option ? [target, option] : [target])
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
end
