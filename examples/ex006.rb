# X-Y data plot from file
fn = "tmp.dat"
open(fn,"w") do |f|
  100.times do |i|
    x = i*0.1
    f.printf("%g %g\n", x, Math.sin(x))
  end
end

Numo.gnuplot do
  set title:"X-Y data plot from file"
  # if 'using' option is given,
  # the first string argument is regarded as a data file.
  plot fn, using:[1,2], w:'lines', t:'sin(x)'
end
