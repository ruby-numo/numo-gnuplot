require "numo/gnuplot"
require "numo/narray"
DF = Numo::DFloat
NM = Numo::NMath

# 3D plot of XYZ data with Numo::NArray

Numo::Gnuplot.new.instance_eval do
  n = 120
  x = (DF.new(1,n).seq/n-0.5)*30
  y = (DF.new(n,1).seq/n-0.5)*30
  r = NM.sqrt(x**2+y**2) + 1e-10
  z = NM.sin(r)/r
  x += DF.zeros(n,1)
  y += DF.zeros(1,n)

  set title:'3D plot of XYZ data',
      palette:{rgbformula:[22,13,-31]},
      dgrid3d:[60,60],
      xlabel:'x',
      ylabel:'y',
      zlabel:'sin(r)/r'
  splot x,y,z, w:'pm3d', t:'sin(r)/r'
  gets
end
