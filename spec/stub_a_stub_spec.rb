# coding: utf-8
require 'stub_a'

describe StubA, "#stub" do
  class Baz
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
      yield(a, b)
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

  let(:log) { [] }

  context "クラスを操作した場合" do
    context "存在するインスタンスメソッドを指定した場合" do
      let(:target) { Baz.dup }

      include_context "shared stub"

      before do
        stub.stub(:first) do |_|
          @log.push(:stub)
          @log
        end
      end

      it "書き換えたオリジナルメソッドが作成されていること" do
        expect(target.method_defined? origin_first_method_name).to be true
      end

      it "作成したインスタンスにも書き換えたメソッドが作成されていること" do
        expect(target.new(log).respond_to? origin_first_method_name).to be true
      end

      it "stub メソッドが作成されていること" do
        expect(target.method_defined? stub_first_method_name).to be true
      end

      it "指定していない before フックは作成されていないこと" do
        expect(target.method_defined? before_first_method_name).to be false
      end

      it "作成したインスタンスにも stub メソッドが作成されていること" do
        expect(target.new(log).respond_to? stub_first_method_name).to be true
      end

      context "引数を伴わないメソッドの場合" do
        it "オリジナルメソッドがオリジナルどおりに動作すること" do
          expect(target.new(log).__send__ origin_first_method_name).to eq [:origin]
        end

        it "オリジナルメソッドの代わりに stub が実行されること" do
          expect(target.new(log).first).to eq [:stub]
        end
      end

      context "引数を伴うメソッドの場合" do
        before do
          stub.stub(:second) {|arg|
            @log.push(:stub)
            @log.push(arg.args)
            @log
          }
        end

        it "オリジナルメソッドがオリジナルどおりに動作すること" do
          method = origin_second_method_name
          value = target.new(log).__send__ method, :arg1, :arg2
          expect(value).to eq [:origin, [:arg1, :arg2]]
        end

        it "オリジナルメソッドの代わりに stub が実行されること" do
          value = target.new(log).second(1, 2)
          expect(value).to eq [:stub, [1, 2]]
        end
      end

      context "引数とブロックを伴うメソッドの場合" do
        before do
          stub.stub(:third) do |arg, &block|
            @log.push(:stub)
            @log.push(arg.args)
            block.call(*arg.args) if block
            @log
          end
        end

        it "オリジナルメソッドがオリジナルどおりに動作すること" do
          method = origin_third_method_name
          value = target.new(log).__send__(method, :a, :b) do |x, y|
            log.push(:origin_block)
            log.push([x, y])
          end
          expect(value).to eq [:origin, :origin_block, [:a, :b]]
        end

        it "オリジナルメソッドの代わりに stub が実行されること" do
          value = target.new(log).third(:a, :b) do |a, b|
            log.push(:origin_block)
            log.push([a, b])
          end
          expect(value).to eq [:stub, [:a, :b], :origin_block, [:a, :b]]
        end
      end
    end
  end

  context "インスタンスを操作した場合" do
    let(:target) { Baz.new(log) }

    context "存在するインスタンスメソッドを指定した場合" do
      include_context "shared stub"

      before do
        stub.stub(:first) do |*|
          @log.push(:stub)
          @log
        end
      end

      it "書き換えたオリジナルメソッドが作成されていること" do
        expect(target.respond_to? origin_first_method_name).to be true
      end

      it "別のインスタンスには書き換えたメソッドが作成されていないこと" do
        expect(Baz.new(log).respond_to? origin_first_method_name).to be false
      end

      it "stub メソッドが作成されていること" do
        expect(target.respond_to? stub_first_method_name).to be true
      end

      it "指定していない before フックは作成されていないこと" do
        expect(target.respond_to? before_first_method_name).to be false
      end

      it "別のインスタンスには stub メソッドが作成されていないこと" do
        expect(Baz.new(log).respond_to? stub_first_method_name).to be false
      end

      context "引数を伴わないメソッドの場合" do
        it "オリジナルメソッドがオリジナルどおりに動作すること" do
          expect(target.__send__ origin_first_method_name).to eq [:origin]
        end

        it "オリジナルのメソッドの代わりに stub が実行されること" do
          expect(target.first).to eq [:stub]
        end

        it "別のインスタンスの動作には影響がないこと" do
          expect(Baz.new(log).first).to eq [:origin]
        end
      end

      context "引数を伴うメソッドの場合" do
        before do
          stub.stub(:second) {|arg|
            @log.push(:stub)
            @log.push(arg.args)
            @log
          }
        end

        it "オリジナルメソッドがオリジナルどおりに動作すること" do
          method = origin_second_method_name
          value = target.__send__ method, 1, 2
          expect(value).to eq [:origin, [1, 2]]
        end

        it "オリジナルのメソッドの代わりに stub が実行されること" do
          value = target.second(:a, :b)
          expect(value).to eq [:stub, [:a, :b]]
        end

        it "別のインスタンスの動作には影響がないこと" do
          value = Baz.new(log).second(:a, :b)
          expect(value).to eq [:origin, [:a, :b]]
        end
      end

      context "引数とブロックを伴うメソッドの場合" do
        before do
          stub.stub(:third) do |arg, &block|
            @log.push(:stub)
            @log.push(arg.args)
            block.call(*arg.args) if block
            @log
          end
        end

        it "オリジナルメソッドがオリジナルどおりに動作すること" do
          method = origin_third_method_name
          value = target.__send__(method, 1, 2) {|x, y|
            log.push(:origin_block)
            log.push([x, y])
          }
          expect(value).to eq [:origin, :origin_block, [1, 2]]
        end

        it "オリジナルメソッドの代わりに stub が実行されること" do
          value = target.third(1, 2) do |x, y|
            log.push(:origin_block)
            log.push([x, y])
          end
          expect(value).to eq [:stub, [1, 2], :origin_block, [1, 2]]
        end
      end
    end
  end
end
