require 'numo/gnuplot'
require 'numo/narray'
DF = Numo::DFloat
NM = Numo::NMath

# multiple data series plot (Hash separated)

Numo.gnuplot do
  n = 60
  x = DF[-n..n]/n*10
  set title:"multiple data series plot"
  plot x,NM.sin(x), {w:'points',t:'sin(x)'}, x,x*NM.sin(x),{w:"lines",t:'x*sin(x)'}
  gets
end
