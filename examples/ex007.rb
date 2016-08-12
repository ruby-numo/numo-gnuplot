x = ['a','b','c','d','e']
y = [10,20,40,30,45]

Numo.gnuplot do
  set title:'Bar chart with text labels'
  set boxwidth:0.5
  set 'grid'
  set yrange:[0..50]
  set style:[fill:'solid']
  plot x,y, using:[2, 'xtic(1)'], w:'boxes', t:'series'
end
