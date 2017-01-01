require "numo/narray"

# 3D plot of XYZ data with Numo::NArray
df = Numo::DFloat
nm = Numo::NMath
n = 120
x = (df.new(1,n).seq/n-0.5)*30
y = (df.new(n,1).seq/n-0.5)*30
r = nm.sqrt(x**2+y**2) + 1e-10
z = nm.sin(r)/r
x += df.zeros(n,1)
y += df.zeros(1,n)

Numo.gnuplot do
  set title:'3D plot of XYZ data'
  set palette:{rgbformula:[22,13,-31]}
  set dgrid3d:[60,60]
  set xlabel:'x'
  set ylabel:'y'
  set zlabel:'sin(r)/r'
  splot x,y,z, w:'pm3d', t:'sin(r)/r'
end
