require "numo/gnuplot"

Numo.gnuplot do
  set xrange:-5..10
  set title:'Math function example'
  set xlabel:'x'
  set ylabel:'y'
  plot 'x*sin(x)', with:'lines', lt:{rgb:'blue',lw:3}
  gets
end
