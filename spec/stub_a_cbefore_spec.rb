# coding: utf-8
require 'spec_helper'

describe StubA, "#cbefore" do
  let(:log) { [] }

  context "クラスを操作対象として指定した場合" do
    context "存在するクラスメソッドを指定した場合" do
      let(:target) { Foo.dup }
      let(:target_class) { class << target; self; end }

      include_context "shared stub"

      before do
        stub.cbefore(:zweit) {|a|
          log = a.args.first
          log.push("before (#{a.method_name})")
          log.push(a.args[1..-1])
          log
        }
      end

      it "書き換えたオリジナルメソッドが作成されていること" do
        expect(target_class.method_defined? origin_zweit_method_name).to be true
      end

      it "before フックが作成されていること" do
        expect(target_class.method_defined? before_zweit_method_name).to be true
      end

      it "指定していない after フックは作成されていないこと" do
        expect(target_class.method_defined? after_zweit_method_name).to be false
      end

      context "ブロックを伴わないメソッドの場合" do
        it "オリジナルメソッドがオリジナルどおりに動作すること" do
          method_name = origin_zweit_method_name
          value = target.__send__ method_name, log, :arg1, :arg2
          expect(value).to eq [:origin, [:arg1, :arg2]]
        end

        it "メソッド実行の前に before フックも実行されること" do
          value = target.zweit(log, 1, 2)
          expect(value).to eq ["before (zweit)", [1, 2], :origin, [1, 2]]
        end
      end
    end
  end
end
