module Numo

  def gnuplot(&block)
    Gnuplot.default.instance_eval(&block)
  end
  module_function :gnuplot

class Gnuplot

  VERSION = "0.1.0"
  POOL = []
  DATA_FORMAT = "%.5g"

  class GnuplotError < StandardError; end

  def self.default
    POOL[0] ||= self.new
  end

  def initialize
    @history = []
    @iow = IO.popen("gnuplot 2>&1","w+")
    @ior = @iow
    @gnuplot_version = send_cmd("print GPVAL_VERSION")
    @debug = false
  end

  attr_reader :history
  attr_reader :gnuplot_version

  def plot(*args)
    _plot_splot("plot",args)
  end

  def splot(*args)
    _plot_splot("splot",args)
  end

  def _plot_splot(cmd,args)
    contents = parse_plot_args(args)
    r = contents.shift.map{|x|"[#{x.begin}:#{x.end}] "}.join
    c = contents.map{|x| x.cmd_str}.join(",")
    d = contents.map{|x| x.data_str}.join("")
    run "#{cmd} #{r}#{c}\n#{d}"
    @last_data = d
  end

  def replot
    run "replot\n#{@last_data}"
  end

  def set(*args)
    _set_unset("set",args)
  end

  def unset(*args)
    _set_unset("unset",args)
  end

  def _set_unset(cmd,args)
    args.each do |a|
      case a
      when Hash
        a.each do |k,v|
          run "#{cmd} #{KvItem.new(k,v)}"
        end
      else
        run "#{cmd} #{a}"
      end
    end
  end

  def help(s=nil)
    puts send_cmd "help #{s}\n\n"
  end

  def show(x)
    puts send_cmd "show #{x}"
  end

  def reset(*args)
    args.each do |a|
      run "reset #{a}"
    end
  end

  # gnuplot commands without argument
  %w[
    clear
    exit
    quit
    refresh
  ].each do |m|
    define_method(m){run m}
  end

  #other_commands = %w[
  #  bind
  #  call
  #  cd
  #  do
  #  evaluate
  #  fit
  #  history
  #  if
  #  load
  #  lower
  #  pause
  #  print
  #  pwd
  #  raise
  #  reread
  #  save
  #  shell
  #  stats
  #  system
  #  test
  #  update
  #  while
  #]

  # for irb workspace name
  def to_s
    "gnuplot"
  end

  def run(s)
    res = send_cmd(s)
    if !res.empty?
      if res.size > 7
        msg = "\n"+res[0..5].join("")+" :\n"
      else
        msg = "\n"+res.join("")
      end
      raise GnuplotError,msg
    end
  end

  def send_cmd(s)
    puts "<"+s if @debug
    @iow.puts s
    @iow.puts "print 'end_of_cmd'"
    @iow.flush
    @history << s
    res = []
    while line=@ior.gets
      puts ">"+line if @debug
      break if /^end_of_cmd$/ =~ line
      res << line
    end
    res # = res.chomp.strip
  end

  def parse_plot_args(args)
    contents = [[]]
    content = PlotItem.new
    contents << content
    args.each do |a|
      case a
      when Range
        contents.first << a
      when Array
        if a.all?{|e| e.kind_of?(Range)}
          contents.first.concat(a)
        elsif PlotItem.is_data(a)
          content << a
        else
          if contents.last.empty?
            contents.pop
          end
          content = PlotItem.new(*a)
          contents << content
        end
      when Hash
        content << a
        content = PlotItem.new
        contents << content
      else
        content << a
      end
    end
    if contents.last.empty?
      contents.pop
    end
    return contents
  end


  class OptsToS
    def initialize(*opts)
      @opts = opts
    end

    def to_s
      opts_to_s(*@opts)
    end

    def opts_to_s(*opts)
      #p opts
      sep = ","
      opts.map do |opt|
        sep = " " if !opt.kind_of?(Numeric)
        case opt
        when Array
          opt.map{|v| "#{opts_to_s(*v)}"}.join(sep)
        when Hash
          opt.map{|k,v| KvItem.new(k,v).to_s}.compact.join(" ")
        when Range
          "[#{opt.begin}:#{opt.end}]"
        else
          opt.to_s
        end
      end.join(sep)
    end
  end


  class KvItem
    NEED_QUOTE = %w[
      background
      cblabel
      clabel
      dashtype
      dt
      font
      format
      format_cb
      format_x
      format_x2
      format_xy
      format_y
      format_y2
      format_z
      output
      rgb
      timefmt
      title
      x2label
      xlabel
      y2label
      ylabel
      zlabel
    ].map{|x| x.to_sym}

    def initialize(k,v)
      @k = k
      @v = v
    end

    def need_quote?(k)
      NEED_QUOTE.any? do |q|
        /^#{k}/ =~ q
      end
    end

    def to_s
      kv_to_s(@k,@v)
    end

    def kv_to_s(k,v)
      if need_quote?(k)
        case v
        when String
          "#{k} #{v.inspect}"
        when Array
          "#{k} #{v[0].inspect} #{OptsToS.new(*v[1..-1])}"
        end
      else
        case v
        when String
          "#{k} #{v}"
        when TrueClass
          "#{k}"
        when NilClass
          nil
        when FalseClass
          nil
        when Array
          "#{k} #{OptsToS.new(*v)}"
        else
          "#{k} #{OptsToS.new(v)}"
        end
      end
    end
  end # KvItem


  class PlotItem

    def self.is_data(a)
      if a.kind_of? Array
        if a.last.kind_of?(Hash)
          return false
        else
          t = a.first.class
          t = Numeric if t < Numeric
          return a.all?{|e| e.kind_of?(t)}
        end
      elsif defined?(Numo::NArray)
        return true if a.kind_of?(Numo::NArray)
      elsif defined?(NArray)
        return true if a.kind_of?(NArray)
      elsif defined?(NMatrix)
        return true if a.kind_of?(NMatix)
      end
      false
    end

    def initialize(*items)
      @items = items
    end

    def <<(item)
      @items << item
    end

    def empty?
      @items.empty?
    end

    def parse_items
      if !@options
        if @items.empty?
          return
        elsif @items.first.kind_of? String
          @function = @items.first
          @options = @items[1..-1]
        else
          @data = []
          @options = []
          @items.each do |x|
            if PlotItem.is_data(x)
              @data << x
            else
              @options << x
            end
          end
          if @data.size==1
            a = @data[0]
            if a.respond_to?(:shape)
              if a.shape.size == 2
                @matrix = true
              end
            end
          end
        end
      end
    end

    def cmd_str
      parse_items
      if @function
        "%s %s" % [@function, OptsToS.new(*@options)]
      else
        if @matrix
          "'-' matrix %s" % OptsToS.new(*@options)
        else
          "'-' %s" % OptsToS.new(*@options)
        end
      end
    end

    def data_str
      parse_items
      if @function
        ''
      else
        if @matrix
          data2d_to_s(@data[0])+"\ne\n"
        else
          data1d_to_s(*@data)+"e\n"
        end
      end
    end

    def data_format
      @data_format || DATA_FORMAT
    end

    def data_format=(s)
      @data_format = s
    end

    def data1d_to_s(*a)
      n = a.map{|e| e.size}.min
      f = ([data_format]*a.size).join(" ")+"\n"
      s = ""
      n.times{|i| s << f % a.map{|e| e[i]}}
      s
    end

    def data2d_to_s(a)
      f = data_format
      s = ""
      a.to_a.each do |b|
        s << b.map{|e| f%e}.join(" ")+"\n"
      end
      s
    end
  end # PlotItem
end # Numo::Gnuplot
end
