# X-Y data plot

x = 20.times.map{|i| i*0.5}
y = x.map{|i| i*Math.sin(i)}

Numo.gnuplot do
  set title:'X-Y data plot example'
  set xlabel:'x'
  set ylabel:'y'
  plot x,y, with:'lp', lt:{rgb:'blue',lw:3}
end
