require 'numo/narray'

# X-Y data plot with Numo::NArray
x = Numo::DFloat[0..100]/10
y = Numo::NMath.sin(x)

Numo.gnuplot do
  set title:"X-Y data plot with Numo::NArray"
  plot x,y, w:'lines', t:'sin(x)'
end
