# Numo::Gnuplot : Gnuplot interface for Ruby

<div class="row">
<a href=https://github.com/ruby-numo/numo-gnuplot-demo/blob/master/gnuplot/md/006histograms/README.md>
<img src="https://raw.githubusercontent.com/ruby-numo/numo-gnuplot-demo/master/gnuplot/md/006histograms/image/006.png" height="135" width="135">
</a>
<a href=https://github.com/ruby-numo/numo-gnuplot-demo/blob/master/gnuplot/md/501rainbow/README.md>
<img src="https://raw.githubusercontent.com/ruby-numo/numo-gnuplot-demo/master/gnuplot/md/501rainbow/image/002.png" height="135" width="135">
</a>
<a href=https://github.com/ruby-numo/numo-gnuplot-demo/blob/master/gnuplot/md/603finance/README.md>
<img src="https://raw.githubusercontent.com/ruby-numo/numo-gnuplot-demo/master/gnuplot/md/603finance/image/013.png" height="135" width="135">
</a>
<a href=https://github.com/ruby-numo/numo-gnuplot-demo/blob/master/gnuplot/md/502rgb_variable/README.md>
<img src="https://raw.githubusercontent.com/ruby-numo/numo-gnuplot-demo/master/gnuplot/md/502rgb_variable/image/006.png" height="135" width="135">
</a>
<a href=https://github.com/ruby-numo/numo-gnuplot-demo/blob/master/gnuplot/md/207hidden2/README.md>
<img src="https://raw.githubusercontent.com/ruby-numo/numo-gnuplot-demo/master/gnuplot/md/207hidden2/image/001.png" height="135" width="135">
</a>
<a href=https://github.com/ruby-numo/numo-gnuplot-demo/blob/master/gnuplot/md/905transparent_solids/README.md>
<img src="https://raw.githubusercontent.com/ruby-numo/numo-gnuplot-demo/master/gnuplot/md/905transparent_solids/image/002.png" height="135" width="135">
</a>
</div>

Alpha version under development.

* [GitHub site](https://github.com/ruby-numo/numo-gnuplot)
* [RubyGems site](https://rubygems.org/gems/numo-gnuplot)
* [Demo repository](https://github.com/ruby-numo/numo-gnuplot-demo) contains > 500 plots!

* [API doc](http://www.rubydoc.info/gems/numo-gnuplot/Numo/Gnuplot)
* [Introduction.ja](https://github.com/ruby-numo/numo-gnuplot/wiki/Introduction.ja) (in Japanese)

Although there are many [other Gnuplot interface libraries for Ruby](https://github.com/ruby-numo/numo-gnuplot#related-work),
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

## Demo

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

* Plotting X-Y data stored in arrays.

```ruby
require "numo/gnuplot"

x = (0..100).map{|i| i*0.1}
y = x.map{|i| Math.sin(i)}

Numo.gnuplot do
  set title:"X-Y data plot"
  plot x,y, w:'lines', t:'sin(x)'
end
```

* Plotting X-Y data stored in NArrays.

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

  # Hash-separated form
  plot x,NM.sin(x), {w:'points',t:'sin(x)'}, x,x*NM.sin(x),{w:"lines",t:'x*sin(x)'}

  # or Array-separated form
  plot [x,NM.sin(x), w:'points',t:'sin(x)'], [x,x*NM.sin(x),w:"lines",t:'x*sin(x)']
  # (here last item in each Array should be Hash, to distinguish from data array)

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
* fit(*args)
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
* update(*files)

Numo::Gnuplot class methods renamed from Gnuplot commands:

* raise_plot(plot_window) -- 'raise' command
* lower_plot(plot_window) -- 'lower' command

Numo::Gnuplot-specific methods:

* debug_off  -- turn off debug print.
* debug_on  -- turn on debug print.
* run(command_line) -- send command-line string to Gnuplot directly.
* output(filename,[term,*opts]) -- output current plot to file. If term is omitted, an extension in filename is regarded as a term name. This invokes the next commands;
```ruby
set terminal:[term,*opts]
set output:filename; refresh
```
* var(name) -- returns variable content in the Gnuplot context.

See [API doc](http://www.rubydoc.info/gems/numo-gnuplot/Numo/Gnuplot) for more.

## Related Work

* [Ruby Gnuplot](https://github.com/rdp/ruby_gnuplot)
* [ruby-plot](https://github.com/davor/ruby-plot)
* [GNUPlotr](https://github.com/pbosetti/gnuplotr)
* [GnuPlotter](https://github.com/maasha/gnuplotter)
* [scbi_plot](https://rubygems.org/gems/scbi_plot)
* [GnuplotRB](https://github.com/dilcom/gnuplotrb)
* [NumPlot](https://rubygems.org/gems/numplot)

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/ruby-numo/numo-gnuplot.
