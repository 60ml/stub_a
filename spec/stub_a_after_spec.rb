# coding: utf-8
require 'spec_helper'

describe StubA, "#after" do
  class Baa
    def initialize(log)
      @log = log
    end

    def first
      @log.push(:origin)
      @log
    end

    def second(x, y)
      @log.push(:origin)
      @log.push([x, y])
      @log
    end

    def third(x, y)
      @log.push(:origin)
      yield(@log, x, y)
      @log
    end
  end

  let(:log) { [] }

  context "インスタンスを操作した場合" do
    let(:target) { Baa.new(log) }

    context "存在するインスタンスメソッドを指定した場合" do
      include_context "shared stub"

      before do
        stub.after(:first) do |arg|
          @log.push("after (#{arg.method_name})")
        end
      end

      it "書き換えたオリジナルメソッドが作成されていること" do
        expect(target.respond_to? origin_first_method_name).to be true
      end

      it "別のインスタンスには書き換えたメソッドが作成されていないこと" do
        expect(Baa.new(log).respond_to? origin_first_method_name).to be false
      end

      it "after フックが作成されていること" do
        expect(target.respond_to? after_first_method_name).to be true
      end

      it "指定していない before フックが作成されていないこと" do
        expect(target.respond_to? before_first_method_name).to be false
      end

      it "別のインスタンスには after フックが作成されていないこと" do
        expect(Baa.new(log).respond_to? after_first_method_name).to be false
      end

      it "オリジナルメソッドがオリジナルどおりに動作すること" do
        expect(target.__send__ origin_first_method_name).to eq [:origin]
      end

      it "メソッド実行の後に after フックも実行されること" do
        expect(target.first).to eq [:origin, "after (first)"]
      end
    end
  end
end

