# coding: utf-8

class StubA
  # コンストラクタ
  #
  # StubA は、コンストラクタに操作対象のオブジェクトを要求します。
  #
  # 操作対象としてインスタンスを渡すと、StubA インスタンスを通して
  # 対象のインスタンスメソッドにフックやスタブを適用できるように
  # なります。操作を通じて作成されるフックやスタブは特異メソッド
  # として作成されますので、指定したインスタンスのみの動作を変更
  # できます。
  #
  #  array = [1, 2, 3]
  #  stub = StubA.new(array)
  #  stub.before(:unshift) do ...
  #
  # コンストラクタに操作対象のクラスを渡した場合、StubA インスタンスを
  # 通して、対象のインスタンスメソッドとクラスメソッドにフックや
  # スタブを適用できるようになります。ただしクラスメソッドを操作
  # する場合は、+class: true+ というオプションをつける必要があります。
  #
  #  stub = StubA.new(User, class: true)
  #  stub.before(:where) do ...
  #
  def initialize(object, option={})
    if object.is_a? Class
      @target_class = object unless option[:class]
    elsif option[:class]
      raise
    end
    @target_class ||= class << object; self; end
  end

  [:before,
   :after,
  ].each do |hook_type|
    define_method hook_type, ->(method, &block) {
      make_hook_points(method)

      method_name = hook_method_name(method, hook_type)
      hook = block if block
      hook ||= default_hook(method, hook_type)
      @target_class.__send__ :define_method, method_name, hook
      self
    }
  end

  def stub(method, &block)
    raise ArgumentError, "No block" unless block
    make_hook_points(method)

    method_name = hook_method_name(method, :stub)
    @target_class.__send__ :define_method, method_name, block
    self
  end

  def restore(method=nil, *types)
    if method.nil?
      hooks = defined_hooks
      method = hooks.keys.first if hooks.keys.size == 1
    end
    raise "Method name to be restored is required." if method.nil?

    available_types = METHOD_TYPES - [:origin]
    raise "Type error" if (types - available_types).size > 0
    types = available_types if types.empty?
    types.uniq!

    types.each do |type|
      method_name = hook_method_name(method, type)
      next unless @target_class.method_defined? method_name
      @target_class.__send__ :remove_method, method_name
    end

    hooks = defined_hooks
    if hooks[method.to_s].size == 1 and
      hooks[method.to_s].first == 'origin'
      origin = hook_method_name(method, :origin)
      @target_class.__send__ :alias_method, method, origin
      @target_class.__send__ :remove_method, origin
    end
  end

  def restore_all
    defined_hooks.each do |method, types|
      types.each do |type|
        name = hook_method_name(method, type)
        next unless @target_class.method_defined? name
        @target_class.__send__ :alias_method, method, name if type == 'origin'
        @target_class.__send__ :remove_method, name
      end
    end
  end
  
  private
  METHOD_TYPES = [
    :before,
    :after,
    :stub,
    :origin,
  ]
  private_constant :METHOD_TYPES

  def hook_method_name(method, type)
    "===>(stub_a) #{type}-#{method}"
  end

  def hook_method_names(method)
    METHOD_TYPES.each_with_object({}) do |t, h|
      h[t] = hook_method_name(method, t)
    end
  end

  def make_hook_points(method_name)
    methods = hook_method_names(method_name)
    return if @target_class.method_defined? methods[:origin]

    @target_class.__send__ :alias_method, methods[:origin], method_name
    @target_class.__send__ :define_method, method_name, ->(*args, &block) {
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
        __send__ methods[:after], ARGS[:after].new(method_name, val)
      end

      val
    }
  end

  def defined_hooks
    re = /\A===>\(stub_a\) (before|after|stub|origin)-(.+)\z/
    @target_class.instance_methods.each_with_object({}) {|name, h|
      if name.to_s =~ re
        h[$2] ||= []
        h[$2] << $1
      end
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
    after: Struct.new(:method_name, :return_value),
  }
  private_constant :ARGS
end
