require "numo/narray"

# 3D plot of 2D data with Numo::NArray
n = 60
x = (Numo::DFloat.new(1,n).seq/n-0.5)*30
y = (Numo::DFloat.new(n,1).seq/n-0.5)*30
r = Numo::NMath.sqrt(x**2+y**2) + 1e-10
z = Numo::NMath.sin(r)/r

Numo.gnuplot do
  set title:'3D plot of 2D data'
  set dgrid3d:[60,60]
  splot z, w:'pm3d', t:'sin(r)/r'
end
