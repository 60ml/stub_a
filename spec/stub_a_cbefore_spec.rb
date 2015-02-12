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

      context "ブロックを伴うメソッドの場合" do
        before do
          stub.cbefore(:dritt) {|a|
            log = a.args.first
            log.push("before (#{a.method_name})")
            log.push(a.args[1..-1])
          }
        end

        it "オリジナルメソッドがオリジナルどおりに動作すること" do
          method_name = origin_dritt_method_name
          value = target.__send__(method_name, log, :a, :b) {|array, x, y|
            array.push(:origin_block)
            array.push([x, y])
          }
          expect(value).to eq [:origin, :origin_block, [:a, :b]]
        end

        it "メソッド実行の前に before フックも実行されること" do
          value = target.dritt(log, 9, 8) do |array, x, y|
            array.push(:origin_block)
            array.push([x, y])
          end
          expect(value).to eq ["before (dritt)", [9, 8], :origin,
                               :origin_block, [9, 8]]
        end
      end
    end

    context "存在しないメソッドを指定した場合" do
      let(:target) { Foo.dup }

      it "エラーが発生すること" do
        expect{
          StubA.new(target).cbefore(:foo) {|_| :a }
        }.to raise_error
      end

      it "書き換えメソッドが作成されていないこと" do
        stub = StubA.new(target)
        begin
          stub.cbefore(:foo) {|_| :b }
        rescue
        end
        expect(target.methods.select {|m| m.to_s =~ /stub_a/ }).to be_empty
      end
    end
  end
end
