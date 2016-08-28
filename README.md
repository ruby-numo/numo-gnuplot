# Numo::Gnuplot : Gnuplot interface for Ruby

* Alpha version under development.
* [GitHub site](https://github.com/ruby-numo/gnuplot)
* [RubyGems site](https://rubygems.org/gems/numo-gnuplot)
* [API doc](http://www.rubydoc.info/gems/numo-gnuplot/Numo/Gnuplot)

Although there are many [other Gnuplot interface libraries for Ruby](https://github.com/ruby-numo/gnuplot#related-work),
none of them have so simple interface as to show an XY data plot by just typing:

    plot x,y

Numo::Gnuplot achieves this by providing only one class which has
the same inteface as Gnuplot command line, and no other class which
causes extra learning costs.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'numo-gnuplot'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install numo-gnuplot

## Demo page

* [Ruby/Numo::Gnuplot Demo](https://github.com/ruby-numo/numo-gnuplot-demo)

## Usage

* All examples require to load Numo::Gnuplot class:

```ruby
require "numo/gnuplot"
```

* The first example showing how it works.

```ruby
gp = Numo::Gnuplot.new
gp.set title:"Example Plot"
gp.plot "sin(x)",w:"lines"
```

* You can omit receiver.

```ruby
Numo::Gnuplot.new.instance_eval do
  set title:"Example Plot"
  plot "sin(x)",w:"lines"
end
```

* The same thing in short.

```ruby
Numo.gnuplot do
  set title:"Example Plot"
  plot "sin(x)",w:"lines"
end
```

* In these examples, the following command lines are send to Gnuplot.

```
set title "Example Plot"
plot sin(x) w lines
```

* Interactive plotting with IRB:

```
$ irb -r numo/gnuplot
irb(main):001:0> pushb Numo.gnuplot
irb(gnuplot):002:0> set t:"Example Plot"
irb(gnuplot):003:0> plot "sin(x)",w:"lines"
```

* Plotting X-Y data.

```ruby
require "numo/gnuplot"

x = (0..100).map{|i| i*0.1}
y = x.map{|i| Math.sin(i)}

Numo.gnuplot do
  set title:"X-Y data plot"
  plot x,y, w:'lines', t:'sin(x)'
end
```

* Plotting X-Y data in NArray.

```ruby
require "numo/gnuplot"
require "numo/narray"

x = Numo::DFloat[0..100]/10
y = Numo::NMath.sin(x)

Numo.gnuplot do
  set title:"X-Y data plot in Numo::NArray"
  plot x,y, w:'lines', t:'sin(x)'
end
```

* Multiple data are separated by Hash or put into Array.

```ruby
require 'numo/gnuplot'
require 'numo/narray'
NM = Numo::NMath

n = 60
x = Numo::DFloat[-n..n]/n*10

Numo.gnuplot do
  set title:"multiple data series"
  # place next data after option Hash
  plot x,NM.sin(x), {w:'points',t:'sin(x)'}, x,x*NM.sin(x),{w:"lines",t:'x*sin(x)'}
  # or place data and options in Array
  # plot [x,NM.sin(x), w:'points',t:'sin(x)'], [x,x*NM.sin(x),w:"lines",t:'x*sin(x)']
  # (here last item in each Array should be Hash in order to distinguish from array data)
  gets
end
```

* Plotting 2D arrays in 3D.

```ruby
require 'numo/gnuplot'
require 'numo/narray'

n = 60
x = (Numo::DFloat.new(1,n).seq/n-0.5)*30
y = (Numo::DFloat.new(n,1).seq/n-0.5)*30
r = Numo::NMath.sqrt(x**2+y**2) + 1e-10
z = Numo::NMath.sin(r)/r

Numo.gnuplot do
  set title:'2D data plot'
  set dgrid3d:[60,60]
  splot z, w:'pm3d', t:'sin(r)/r'
end
```

### IRuby
Numo::Gnuplot is compatible with [IRuby](https://github.com/SciRuby/iruby/).

* Embedding a plot into iRuby Notebook.

```ruby
Numo::Gnuplot::NotePlot.new do
  plot "sin(x)"
end
```

* The same thing in short.

```ruby
Numo.noteplot do
  plot "sin(x)"
end
```

## Gnuplot methods

Numo::Gnuplot class methods succeeded from Gnuplot commands:

* clear
* exit
* help(topic)
* load(filename)
* pause(*args)
* plot(*args)
* quit
* reflesh
* replot
* reset(option)
* set(*options)
* show(option)
* splot(*args)
* unset(*options)

Numo::Gnuplot class methods renamed from Gnuplot commands:

* raise_plot(plot_window) -- 'raise' command
* lower_plot(plot_window) -- 'lower' command

Numo::Gnuplot-specific methods:

* debug_off  -- turn off debug print
* debug_on  -- turn on debug print
* output(filename,*opts) -- output current plot to file. This invokes the next commands;
```ruby
set terminal:[ext,*opts], output:filename; refresh
```
* var(name) -- returns variable content in the Gnuplot context.

See [API doc](http://www.rubydoc.info/gems/numo-gnuplot/Numo/Gnuplot) for more.

## Related Work

* [Ruby Gnuplot](https://github.com/rdp/ruby_gnuplot/tree/master)
* [GNUPlotr](https://github.com/pbosetti/gnuplotr)
* [GnuPlotter](https://github.com/maasha/gnuplotter)
* [GnuplotRB](https://github.com/dilcom/gnuplotrb)

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/ruby-numo/gnuplot.
