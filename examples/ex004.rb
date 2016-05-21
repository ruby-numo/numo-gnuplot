require 'numo/gnuplot'

# multiple function plot (Array separated)

Numo.gnuplot do
  set title:"Multiple function plot"
  plot ['sin(x)', w:"lp"],['x*sin(x)',w:"lines"]
  gets
end
