# coding: utf-8
require 'spec_helper'

describe StubA, "#before" do
  let(:log) { [] }

  context "クラスを操作した場合" do
    context "存在するインスタンスメソッドを指定した場合" do
      let(:target) { Foo.dup }

      include_context "shared stub"

      before do
        stub.before(:first) {|a|
          @log.push("before (#{a.method_name})")
        }
      end

      it "書き換えたオリジナルメソッドが作成されていること" do
        expect(target.method_defined? origin_first_method_name).to be true
      end

      it "作成したインスタンスにも書き換えたメソッドが作成されていること" do
        expect(target.new(log).respond_to? origin_first_method_name).to be true
      end

      it "before フックが作成されていること" do
        expect(target.method_defined? before_first_method_name).to be true
      end

      it "指定していない after フックは作成されていないこと" do
        expect(target.method_defined? after_first_method_name).to be false
      end

      it "作成したインスタンスにも before フックが作成されていること" do
        expect(target.new(log).respond_to? before_first_method_name).to be true
      end

      context "引数を伴わないメソッドの場合" do
        it "オリジナルメソッドがオリジナルどおりに動作すること" do
          expect(target.new(log).__send__ origin_first_method_name).to eq [:origin]
        end

        it "メソッド実行の前に before フックも実行されること" do
          expect(target.new(log).first).to eq ["before (first)", :origin]
        end
      end

      context "引数を伴うメソッドの場合" do
        before do
          stub.before(:second) {|a|
            @log.push("before (#{a.method_name})")
            @log.push(a.args)
          }
        end

        it "オリジナルメソッドがオリジナルどおりに動作すること" do
          method = origin_second_method_name
          value = target.new(log).__send__ method, :arg1, :arg2
          expect(value).to eq [:origin, [:arg1, :arg2]]
        end

        it "メソッド実行の前に before フックも実行されること" do
          value = target.new(log).second(1, 2)
          expect(value).to eq ["before (second)", [1, 2], :origin, [1, 2]]
        end
      end

      context "引数とブロックを伴うメソッドの場合" do
        before do
          stub.before(:third) {|a|
            @log.push("before (#{a.method_name})")
            @log.push(a.args)
          }
        end

        it "オリジナルメソッドがオリジナルどおりに動作すること" do
          method = origin_third_method_name
          value = target.new(log).__send__(method, :a, :b) {|array, x, y|
            array.push(:origin_block)
            array.push([x, y])
          }
          expect(value).to eq [:origin, :origin_block, [:a, :b]]
        end

        it "メソッド実行の前に before フックも実行されること" do
          value = target.new(log).third(9, 8) do |a, x, y|
            a.push(:origin_block)
            a.push([x, y])
          end
          expect(value).to eq ["before (third)", [9, 8], :origin,
                               :origin_block, [9, 8]]
        end
      end
    end

    context "存在しないメソッドを指定した場合" do
      let(:target) { Foo.dup }

      it "エラーが発生すること" do
        expect{
          StubA.new(target).before(:foo) {|_| @log.push(:before) }
        }.to raise_error
      end

      it "書き換えメソッドが作成されていないこと" do
        stub = StubA.new(target)
        begin
          stub.before(:foo) {|_| @log.push(:before) }
        rescue
        end
        expect(target.methods.select {|m| m.to_s =~ /stub_a/ }).to be_empty
      end
    end
  end

  context "インスタンスを操作した場合" do
    let(:target) { Foo.new(log) }

    context "存在するインスタンスメソッドを指定した場合" do
      include_context "shared stub"

      before do
        stub.before(:first) do |arg|
          @log.push("before (#{arg.method_name})")
        end
      end

      it "書き換えたオリジナルメソッドが作成されていること" do
        expect(target.respond_to? origin_first_method_name).to be true
      end

      it "別のインスタンスには書き換えたメソッドが作成されていないこと" do
        expect(Foo.new(log).respond_to? origin_first_method_name).to be false
      end

      it "before フックが作成されていること" do
        expect(target.respond_to? before_first_method_name).to be true
      end

      it "指定していない after フックは作成されていないこと" do
        expect(target.respond_to? after_first_method_name).to be false
      end

      it "別のインスタンスには before フックが作成されていないこと" do
        expect(Foo.new(log).respond_to? before_first_method_name).to be false
      end

      context "引数を伴わないメソッドの場合" do
        it "オリジナルメソッドがオリジナルどおりに動作すること" do
          expect(target.__send__ origin_first_method_name).to eq [:origin]
        end

        it "メソッド実行の前に before フックも実行されること" do
          expect(target.first).to eq ["before (first)", :origin]
        end

        it "別のインスタンスの動作には影響がないこと" do
          expect(Foo.new(log).first).to eq [:origin]
        end
      end

      context "引数を伴うメソッドの場合" do
        before do
          stub.before(:second) {|arg|
            @log.push(:before)
            @log.push(arg.args)
          }
        end

        it "オリジナルメソッドがオリジナルどおりに動作すること" do
          method = origin_second_method_name
          value = target.__send__ method, "pee", "kaa"
          expect(value).to eq [:origin, ["pee", "kaa"]]
        end

        it "メソッド実行の前に before フックも実行されること" do
          value = target.second(:a, :b)
          expect(value).to eq [:before, [:a, :b], :origin, [:a, :b]]
        end

        it "別のインスタンスの動作には影響がないこと" do
          value = Foo.new(log).second(:a, :b)
          expect(value).to eq [:origin, [:a, :b]]
        end
      end

      context "引数とブロックを伴うメソッドの場合" do
        before do
          stub.before(:third) {|arg|
            @log.push("before (#{arg.method_name})")
            @log.push(arg.args)
          }
        end

        it "オリジナルメソッドがオリジナルどおりに動作すること" do
          method = origin_third_method_name
          value = target.__send__(method, 1, 2) {|a, x, y|
            a.push(:origin_block)
            a.push([x, y])
          }
          expect(value).to eq [:origin, :origin_block, [1, 2]]
        end

        it "メソッド実行の前に before フックも実行されること" do
          value = target.third(9, 8) do |a, x, y|
            a.push(:origin_block)
            a.push([x, y])
          end
          expect(value).to eq ["before (third)" , [9, 8], :origin,
                               :origin_block, [9, 8]]
        end
      end
    end

    context "存在しないメソッドを指定した場合" do
      it "エラーが発生すること" do
        expect{
          StubA.new(target).before(:baa) {|_| @log.push(:before) }
        }.to raise_error
      end

      it "書き換えメソッドが作成されていないこと" do
        stub = StubA.new(target)
        begin
          stub.before(:baa) {|_| @log.push(:before) }
        rescue
        end
        expect(target.methods.select {|m| m.to_s =~ /stub_a/ }).to be_empty
      end
    end
  end
end
