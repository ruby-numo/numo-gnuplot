# Numo::Gnuplot : Gnuplot interface for Ruby

* Alpha version under development.
* [GitHub site](https://github.com/masa16/numo-gnuplot)

Although there are many [other Gnuplot interface libraries for Ruby](https://github.com/masa16/numo-gnuplot#related-work),
they do not have such simple interface that
the plot of x-y data is obtained by just typing:

    plot x,y

Numo::Gnuplot achieves this by providing only one class which has
the same inteface with Gnuplot command line, and no other class which
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

## Usage

* All examples require to load Numo::Gnuplot class:
```ruby
require "numo/gnuplot"
```

* The first example showing how it works.
```ruby
gp = Numo::Gnuplot.new
gp.set title:"First Example"
gp.plot "sin(x)"
```

* You can avoid receiver.
```ruby
Numo::Gnuplot.new.instance_eval do
  set title:"Second Example"
  plot "sin(x)"
end
```

* The same thing in short.
```ruby
Numo.gnuplot do
  set title:"Third Example"
  plot "sin(x)"
end
```

* Interactive plotting with IRB:
```
$ irb -r numo/gnuplot
irb(main):001:0> pushb Numo::Gnuplot.new
irb(gnuplot):002:0> set title:"Forth Example"
irb(gnuplot):003:0> plot "sin(x)"
```

* Plotting X-Y data arrays.
```ruby
require "numo/gnuplot"
require "numo/narray"

x = Numo::DFloat[0..100]/10
y = Numo::NMath.sin(x)

Numo.gnuplot do
  set title:"X-Y data plot"
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
  # separate by Hash
  plot x,NM.sin(x), {w:'points',t:'sin(x)'}, x,x*NM.sin(x),{w:"lines",t:'x*sin(x)'}
  # or separate into Array
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

## Related Work

* [Ruby Gnuplot](https://github.com/rdp/ruby_gnuplot/tree/master)
* [GNUPlotr](https://github.com/pbosetti/gnuplotr)
* [GnuPlotter](https://github.com/maasha/gnuplotter)
* [GnuplotRB](https://github.com/dilcom/gnuplotrb)

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/[USERNAME]/numo-gnuplot.
