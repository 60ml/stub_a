# coding: utf-8

class StubA
  # コンストラクタ
  #
  # ==詳細
  # 操作対象のクラスまたはインスタンスを渡し、
  # 操作用オブジェクトを作成します。
  #
  # インスタンスが渡された場合、インスタンス
  # メソッドに対するフックは特異メソッドとして
  # 作成されます。
  #
  # クラスメソッドは、もともと特異メソッドの
  # ようなものなので、クラスメソッドに対する操作は
  # インスタンスを渡してもクラスを渡しても
  # 変わりません。
  #
  # ==引数
  # - ++object+: クラスまたはインスタンス
  def initialize(object)
    if object.is_a? Class
      @target = object
      @target_class = class << object; self; end
    else
      @target = class << object; self; end
      @target_class = class << object.class; self; end
    end
  end

  # インスタンスメソッドに対する before フックを作成
  #
  # ==詳細
  # 引数で指定したインスタンスメソッドが実行される
  # 直前に呼ばれるフックメソッドを作成します。
  #
  # 対象のメソッドはメソッド名で指定します。
  #
  # ==引数
  # - ++method_name++: メソッド名
  #
  def before(method_name, &block)
    make_hook(:before, @target, method_name, &block)
  end

  # クラスメソッドに対する before フックを作成
  #
  # ==詳細
  # 引数で指定したクラスメソッドが実行される直前に
  # 呼ばれるフックメソッドを作成します。
  #
  # 対象のメソッドはメソッド名で指定します。
  #
  # ==引数
  # - ++method_name++: メソッド名
  #
  def cbefore(method_name, &block)
    make_hook(:before, @target_class, method_name, &block)
  end

  # インスタンスメソッドに対する after フックを作成
  #
  # ==詳細
  # 引数で指定したインスタンスメソッドが実行される
  # 直後に呼ばれるフックメソッドを作成します。
  #
  # 対象のメソッドはメソッド名で指定します。
  #
  # ==引数
  # - ++method_name++: メソッド名
  #
  def after(method_name, &block)
    make_hook(:after, @target, method_name, &block)
  end

  # クラスメソッドに対する after フックを作成
  #
  # ==詳細
  # 引数で指定したクラスメソッドが実行される直後に
  # 呼ばれるフックメソッドを作成します。
  #
  # 対象のメソッドはメソッド名で指定します。
  #
  # ==引数
  # - ++method_name++: メソッド名
  #
  def cafter(method_name, &block)
    make_hook(:after, @target_class, method_name, &block)
  end

  # インスタンスメソッドに対するスタブメソッドを作成
  #
  # ==詳細
  # 引数で指定したインスタンスメソッドの代わりに呼ばれる
  # 代替メソッドを作成します。
  #
  # 対象のメソッドはメソッド名で指定します。
  #
  # ==引数
  # - ++method_name++: メソッド名
  #
  def stub(method_name, &block)
    make_stub(@target, method_name, &block)
  end

  # クラスメソッドに対するスタブを作成
  #
  # ==詳細
  # 引数で指定したクラスメソッドの代わりに呼ばれる代替
  # メソッドを作成します。
  #
  # 対象のメソッドはメソッド名で指定します。
  #
  # ==引数
  # - ++method_name++: メソッド名
  #
  def cstub(method_name, &block)
    make_stub(@target_class, method_name, &block)
  end

  # インスタンスメソッドを書き戻す
  #
  # ==詳細
  # 引数で指定したメソッドに対して行った操作を元に戻します。
  #
  # 基本的に、第一引数にメソッド名、第二引数に戻したい操作の
  # 種類を指定します。
  #
  # たとえば、++foo++ というメソッドに対して ++before++
  # フックを作成した、という操作を戻したい場合は、
  #
  #  stub_a.restore(:foo, :before)
  #
  # のように指定します。
  # 第一引数のメソッドに対して、戻したい操作の種類が複数ある
  # 場合は、
  #
  #  stub_a.restore(:foo, :before, :after)
  #
  # のように続けて指定することもできます。
  #
  # 逆に第二引数を省略した場合は、第一引数で指定したメソッドに
  # 対して行ったすべての種類の操作を戻します。
  #
  # 操作したメソッドがひとつだけの場合で、かつ操作をすべて
  # 戻して構わない場合は、引数を省略することもできます。
  #
  # ==引数
  # - ++method_name++: メソッド名
  # - ++types++: 操作の種類
  #
  def restore(method_name=nil, *types)
    restore_hooks(@target, method_name, *types)
  end

  # クラスメソッドを書き戻す
  #
  # ==詳細
  # ++restore++ がインスタンスメソッドに対する操作であるのに
  # 対し、++crestore++ はクラスメソッドを操作の対象にします。
  #
  # 詳細については、++restore++ の説明を参照してください。
  #
  def crestore(method_name=nil, *types)
    restore_hooks(@target_class, method_name, *types)
  end

  # すべてのインスタンスメソッドを書き戻す
  #
  # ==詳細
  # インスタンスメソッドに対するすべての操作を書き戻します。
  #
  def restore_all
    restore_all_hooks(@target)
  end

  # すべてのクラスメソッドを書き戻す
  #
  # ==詳細
  # クラスメソッドに対するすべての操作を書き戻します。
  #
  def crestore_all
    restore_all_hooks(@target_class)
  end


  private
  METHOD_TYPES = [
    :before,
    :after,
    :stub,
    :origin,
  ]
  private_constant :METHOD_TYPES

  def make_hook(hook_type, target, method, &block)
    make_hook_points(target, method)

    method_name = hook_method_name(method, hook_type)
    hook = block if block
    hook ||= default_hook(method, hook_type)
    target.__send__ :define_method, method_name, hook
    self
  end

  def make_stub(target, method, &block)
    raise ArgumentError, "No block" unless block
    make_hook_points(target, method)

    method_name = hook_method_name(method, :stub)
    target.__send__ :define_method, method_name, block
    self
  end

  def restore_hooks(target, method=nil, *types)
    if method.nil?
      hooks = defined_hooks(target)
      method = hooks.keys.first if hooks.keys.size == 1
    end
    raise "Method name to be restored is required." if method.nil?

    available_types = METHOD_TYPES - [:origin]
    raise "Type error" if (types - available_types).size > 0
    types = available_types if types.empty?
    types.uniq!

    types.each do |type|
      method_name = hook_method_name(method, type)
      next unless target.method_defined? method_name
      target.__send__ :remove_method, method_name
    end

    hooks = defined_hooks(target)
    if hooks[method.to_s].size == 1 and
      hooks[method.to_s].first == 'origin'
      origin = hook_method_name(method, :origin)
      target.__send__ :alias_method, method, origin
      target.__send__ :remove_method, origin
    end
  end

  def restore_all_hooks(target)
    defined_hooks(target).each do |method, types|
      types.each do |type|
        name = hook_method_name(method, type)
        next unless target.method_defined? name
        target.__send__ :alias_method, method, name if type == 'origin'
        target.__send__ :remove_method, name
      end
    end
  end

  def hook_method_name(method, type)
    "===>(stub_a) #{type}-#{method}"
  end

  def hook_method_names(method)
    METHOD_TYPES.each_with_object({}) do |t, h|
      h[t] = hook_method_name(method, t)
    end
  end

  def make_hook_points(target, method_name)
    methods = hook_method_names(method_name)
    return if target.method_defined? methods[:origin]

    target.__send__ :alias_method, methods[:origin], method_name
    target.__send__ :define_method, method_name, ->(*args, &block) {
      if respond_to? methods[:before]
        __send__ methods[:before], ARGS[:before].new(method_name, args), &block
      end

      if respond_to? methods[:stub]
        origin = __send__ :method, methods[:origin]
        val = __send__ methods[:stub], ARGS[:stub].new(origin, args), &block
      else
        val = __send__ methods[:origin], *args, &block
      end

      if respond_to? methods[:after]
        __send__ methods[:after], ARGS[:after].new(method_name, args, val)
      end

      val
    }
  end

  def defined_hooks(target)
    re = /\A===>\(stub_a\) (#{METHOD_TYPES.join('|')})-(.+)\z/
    target.instance_methods.each_with_object({}) {|name, h|
      next if name.to_s !~ re
      h[$2] ||= []
      h[$2] << $1
    }
  end

  def default_hook(method, type)
    case type.to_sym
    when :before
      default_before_hook(method)
    when :after
      default_after_hook(method)
    end
  end

  def default_before_hook(method)
    ->(arg, &block) {
      puts "[#{Time.now}] call `#{arg.method_name}' (#{self.inspect})"
      puts "args: #{arg.args.inspect}" if arg.args.size > 0
    }
  end

  def default_after_hook(method)
    before_method = hook_method_name(method, :before)
    ->(arg) {
      unless respond_to? before_method
        puts "[#{Time.now}] call `#{arg.method_name}' (#{self.inspect})"
      end
      puts "return: #{arg.return_value.inspect}"
    }
  end

  ARGS = {
    before: Struct.new(:method_name, :args),
    stub: Struct.new(:method, :args),
    after: Struct.new(:method_name, :args, :return_value),
  }
  private_constant :ARGS
end
