require "numo/gnuplot"

gp = Numo.gnuplot

puts "mouse/key on window to continue"
Dir.glob("ex*.rb") do |frb|
  gp.reset
  load frb
  gp.pause mouse:"any"
end

gp.set term:"png"

Dir.glob("ex*.rb") do |frb|
  fimg = File.basename(frb,".rb")+".png"
  gp.reset
  gp.set output:fimg
  load frb
  puts "wrote #{fimg}"
end
