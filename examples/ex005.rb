require 'numo/narray'

# multiple data series plot (Hash separated)
n = 60
x = Numo::DFloat[-n..n]/n*10
nm = Numo::NMath

Numo.gnuplot do
  set title:"multiple data series plot"
  plot x,nm.sin(x), {w:'points',t:'sin(x)'}, x,x*nm.sin(x),{w:"lines",t:'x*sin(x)'}
end
