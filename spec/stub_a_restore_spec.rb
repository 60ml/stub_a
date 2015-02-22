# coding: utf-8
require 'spec_helper'

describe StubA, "#restore" do
  context "クラスを操作した場合" do
    context "1 つのメソッドに before フックを作成した場合" do
      let(:target) { Foo.dup }

      include_context "shared stub"

      before do
        stub.before(:first) {|a| @log.push :before }
      end

      context "引数としてメソッド名と :before を伴って実行した場合" do
        before do
          stub.restore(:first, :before)
        end

        it "書き換えたメソッドが存在しないこと" do
          methods = target.instance_methods.select {|m| m.to_s =~ /stub_a/ }
          expect(methods).to be_empty
        end
      end

      context "引数としてメソッド名だけを伴って実行した場合" do
        before do
          stub.restore(:first)
        end

        it "書き換えたメソッドが存在しないこと" do
          methods = target.instance_methods.select {|m| m.to_s =~ /stub_a/ }
          expect(methods).to be_empty
        end
      end

      context "引数を伴わずに実行した場合" do
        before do
          stub.restore
        end

        it "書き換えたメソッドが存在しないこと" do
          methods = target.instance_methods.select {|m| m.to_s =~ /stub_a/ }
          expect(methods).to be_empty
        end
      end

      context "引数としてメソッド名と :after を伴って実行した場合" do
        before do
          stub.restore(:first, :after)
        end

        it "before フックが存在していること" do
          expect(target.method_defined? before_first_method_name).to be true
        end

        it "書き換えられたオリジナルメソッドが存在していること" do
          expect(target.method_defined? origin_first_method_name).to be true
        end
      end

      context "引数として、操作していないメソッド名を伴って実行した場合" do
        it "エラーが発生すること" do
          expect{ stub.restore(:second) }.to raise_error
        end
      end

      context "引数としてメソッド名と、存在しないフック名を伴って実行した場合" do
        it "エラーが発生すること" do
          expect{ stub.restore(:first, :foo) }.to raise_error
        end
      end
    end

    context "2 つのメソッドに before フックを作成した場合" do
      let(:target) { Foo.dup }

      include_context "shared stub"

      before do
        stub.before(:first) {|a| @log.push :before_1 }
        stub.before(:second) {|a| @log.push :before_2 }
      end

      context "引数としてメソッド名と :before を伴って実行した場合" do
        before do
          stub.restore(:second, :before)
        end
        
        it "対象のメソッドについては書き換えたメソッドが存在しないこと" do
          names = [
            origin_second_method_name,
            before_second_method_name,
            after_second_method_name,
            stub_second_method_name,
          ]
          methods = target.instance_methods.select {|m| names.include? m.to_s }
          expect(methods).to be_empty
        end

        it "対象以外のメソッドについては書き換えたメソッドが存在すること" do
          names = [
            origin_first_method_name,
            before_first_method_name,
          ]
          methods = target.instance_methods.select {|m| names.include? m.to_s }
          expect(methods).to match_array names.map(&:to_sym)
        end
      end

      context "引数としてメソッド名だけを伴って実行した場合" do
        before do
          stub.restore(:second)
        end

        it "対象のメソッドについては書き換えたメソッドが存在しないこと" do
          names = [
            origin_second_method_name,
            before_second_method_name,
            after_second_method_name,
            stub_second_method_name,
          ]
          methods = target.instance_methods.select {|m| names.include? m.to_s }
          expect(methods).to be_empty
        end

        it "対象以外のメソッドについては書き換えたメソッドが存在すること" do
          names = [
            origin_first_method_name,
            before_first_method_name,
          ]
          methods = target.instance_methods.select {|m| names.include? m.to_s }
          expect(methods).to match_array names.map(&:to_sym)
        end
      end

      context "引数としてメソッド名と :after を伴って実行した場合" do
        before do
          stub.restore(:second, :after)
        end

        it "対象のメソッドについて書き換えたメソッドが存在すること" do
          names = [
            origin_second_method_name,
            before_second_method_name,
          ]
          methods = target.instance_methods.select {|m| names.include? m.to_s }
          expect(methods).to match_array names.map(&:to_sym)
        end

        it "対象以外のメソッドについても書き換えたメソッドが存在すること" do
          names = [
            origin_first_method_name,
            before_first_method_name,
          ]
          methods = target.instance_methods.select {|m| names.include? m.to_s }
          expect(methods).to match_array names.map(&:to_sym)
        end
      end

      context "引数を伴わずに実行した場合" do
        it "エラーが発生すること" do
          expect{
            stub.restore
          }.to raise_error
        end
      end

      context "操作していないメソッド名を引数として伴って実行した場合" do
        it "エラーが発生すること" do
          expect{
            stub.restore(:third)
          }.to raise_error
        end
      end
    end
  end
end
