StubA
===========

このクラスは、あるオブジェクトのメソッドをスタブに差し替えたり、
フックしたりすることができるというものです。

とくに `irb` や `rails console` などの対話的な環境で実際に動かしながら、
フックやスタブなどを適用したり、元に戻したりして、ソースコードを解析する手助けに
しようと考えて作成しました。

以下のことができます。

スタブ
-----------

メソッドの内容を差し替えます。
たとえば次のようなクラスがあったとします。

```ruby
class Kitten
  def mew
    "meow"
  end
end
```

これは次のように動きますが、

```
> kitten = Kitten.new
> kitten.mew
=> "meow"
```

スタブを使うと、ブロックで指定した動作に差し替わります。

```
> StubA.new(kitten).stub(:mew) {|*|
>   "hey, boy!"
> }
> kitten.mew
=> "hey, boy!"
```

`StubA` のコンストラクタには操作対象のオブジェクトを渡します。
上記の場合、インスタンスを渡していますので、
スタブが適用されるのはそのインスタンスだけです。

コンストラクタに操作対象のクラスを渡すと、クラス自体にスタブが適用されますので、
操作はインスタンス全体に影響します。

```
> StubA.new(Kitten).stub(:mew) {|_|
>   "hey, come on!"
> }
> Kitten.new.mew
=> "hey, come on!"
```

ただし、最初のように操作を差し替えているインスタンスがすでにある場合
（つまり、特異メソッドで上書きしている場合）には、クラスを後から書き換えても
スタブは適用できません。

```
> Kitten.new.mew
=> "hey, come on!"
> kitten.mew
=> "hey, boy!"
```

引数のあるメソッドの場合、元のメソッドの引数には、ブロックの引数からアクセスできます。

```
> class Kitten
>   def eat(food)
>     "meow! I love #{food}"
>   end
> end
> StubA.new(Kitten).stub(:eat) do |m|
>   "Grr... I get sick of #{m.args.first}"
> end
```

スタブのブロックの引数には、`method` と `args` というフィールドがあり、
それぞれ、元のメソッドとそれに渡された引数が格納されています。

ですので、次のようにすると、元のメソッドを実行できます。

```
> StubA.new(Kitten).stub(:eat) do |m|
>   m.method.call(*m.args)
> end
```

元のメソッドがブロックを伴っている場合、そのブロックにアクセスするには

```
> array = [1, 2, 3]
> StubA.new(array).stub(:map) {|m, &block|
>   m.method.call.size.times.map &block
> }
> array.map {|n| n * 2 }
=> [0, 2, 4]
```

という具合に、引数に追加します。

オブジェクトに対する操作は `restore` メソッドで元に戻すことができます。

```
> StubA.new(array).restore(:map, :stub)
```

第 1 引数がメソッド名、第 2 引数が変更の種類です。スタブの場合は `:stub` を指定します。
第 2 引数を省略すると、指定したメソッドのすべての変更が取り消されます。

正確に言うと `restore` は、変更を元に戻すというよりも
変更前のメソッドに書き直すという動作になっています。

`stub` メソッドも `restore` メソッドも、インスタンスメソッドに対してしか操作できません。
クラスメソッドを操作したい場合は、`stub` の代わりに `cstub`、`restore` の代わりに
`crestore` のように、頭に `c` をつけたメソッドを使ってください。


フック
----------

フックには、`before` と `after` があります。
`before` フックは、メソッドを実行する直前に処理を差し込みます。

```
> stub = StubA.new(Kitten)
> stub.restore(:eat)
>
> class Kitten
>   def eat(food)
>     @weight ||= 0
>     @weight += 10
>     "Yum yum.  I love #{food}"
>   end
> end
>
> stub.before(:eat) do |*|
>   if @weight and @weight >= 50
>     puts "WARNING!"
>   end
> end
>
> kitten = 5.times.inject(Kitten.new) {|k| k.eat(:fish); k }
> kitten.eat(:fish)
WARNING!
=> "Yum yum.  I love fish"
```

ブロックは引数ひとつを伴います。
この引数は `Struct` オブジェクトで、`method_name`、`args`
というフィールドをもっています。
それぞれ元のメソッド名、元のメソッドに渡された引数が格納されます。
メソッド名はシンボルで渡されます。

`after` はメソッド実行後に処理を差し込みます。

```
> stub.after(:eat) do |m|
>   @weight += 100 if m.args.first == :fish
>   puts m.return_value
>   puts @weight
> end
>
> kitten = Kitten.new
> kitten.eat(:fish)
Yum yum.  I love fish
110
=> "Yum yum.  I love fish"
```

`after` が伴うブロックも `Struct` オブジェクトの引数をとります。
フィールドは `method_name` と `args`、`return_value` で、
それぞれ元のメソッド名、メソッドに渡された引数、その戻り値が
格納されます。

それぞれ、`stub` 同様、`restore` で元に戻すことができます。

また、これらのメソッドも `stub` 同様インスタンスメソッドに対する操作
しかできません。クラスメソッドを操作する場合は、`cbefore` や
`cafter` メソッドを使ってください。

ライセンス
------------
MIT ライセンスです。
