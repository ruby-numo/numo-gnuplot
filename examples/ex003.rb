require "numo/gnuplot"
require 'numo/narray'

# X-Y data plot with Numo::NArray
Numo.gnuplot do
  x = Numo::DFloat[0..100]/10
  y = Numo::NMath.sin(x)
  set title:"X-Y data plot with Numo::NArray"
  plot x,y, w:'lines', t:'sin(x)'
  gets
end
