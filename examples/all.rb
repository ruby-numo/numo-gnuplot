require "numo/gnuplot"
#require_relative "../lib/numo/gnuplot"

gp = Numo.gnuplot
#gp.debug_on

puts "Hit enter key to continue"

files = Dir.glob("ex*.rb").sort
files.each do |frb|
  gp.reset
  puts "*** "+frb+" ***"
  load frb
  gets
end

gp.set term:"png"

files.each do |frb|
  fimg = File.basename(frb,".rb")+".png"
  gp.reset
  gp.set output:fimg
  load frb
  puts "wrote #{fimg}"
end
