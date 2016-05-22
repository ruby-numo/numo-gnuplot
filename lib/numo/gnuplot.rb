module Numo

  def gnuplot(&block)
    if block
      Gnuplot.default.instance_eval(&block)
    else
      Gnuplot.default
    end
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

  def initialize(gnuplot_command="gnuplot")
    @history = []
    @iow = IO.popen(gnuplot_command+" 2>&1","w+")
    @ior = @iow
    @gnuplot_version = send_cmd("print GPVAL_VERSION")[0].chomp
    @debug = true
  end

  attr_reader :history
  attr_reader :gnuplot_version

  # draw 2D functions and data.
  def plot(*args)
    _plot_splot("plot",args)
  end

  # draws 2D projections of 3D surfaces and data.
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
  private :_plot_splot

  # replot is not recommended, use refresh
  def replot
    run "replot\n#{@last_data}"
  end

  # The `set` command is used to set _lots_ of options.
  def set(*args)
    _set_unset("set",args)
  end

  # The `unset` command is used to return to their default state.
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
  private :_set_unset

  # The `help` command displays built-in help.
  def help(s=nil)
    puts send_cmd "help #{s}\n\n"
  end

  # The `show` command shows their settings.
  def show(x)
    puts send_cmd "show #{x}"
  end

  #  The `reset` command causes all graph-related options that can be
  #  set with the `set` command to take on their default values.
  def reset(*args)
    args.each do |a|
      run "reset #{a}"
    end
  end

  # The `pause` command used to wait for events on window.
  # Carriage return entry (-1 is given for argument) and
  # text display option is disabled.
  #    pause 10
  #    pause 'mouse'
  #    pause mouse:%w[keypress,button1,button2,button3,close,any]
  def pause(*args)
    send_cmd("pause #{OptsToS.new(*args)}").join.chomp
  end

  # `var` returns Gnuplot variable (not Gnuplot command)
  def var(name)
    res = send_cmd("print #{name}").join("").chomp
    if /undefined variable:/ =~ res
      raise GnuplotError,res.strip
    end
    res
  end

  # The `load` command executes each line of the specified input file.
  def load(filename)
    send_cmd "load '#{filename}'"
  end

  # The `raise` command raises plot window(s)
  def raise(plot_window_nb=nil)
    send_cmd "raise #{plot_window_nb}"
  end

  # The `lower` command lowers plot window(s)
  def lower(plot_window_nb=nil)
    send_cmd "lower #{plot_window_nb}"
  end

  # The `clear` command erases the current screen or output device as specified
  # by `set output`. This usually generates a formfeed on hardcopy devices.
  def clear
    send_cmd "clear"
  end

  # The `exit` and `quit` commands will exit `gnuplot`.
  def exit
    send_cmd "exit"
  end

  # The `exit` and `quit` commands will exit `gnuplot`.
  def quit
    send_cmd "quit"
  end

  # The `refresh` reformats and redraws the current plot using the
  # data already read in.
  def refresh
    send_cmd "reflesh"
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
  #  print
  #  pwd
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
    nil
  end
  private :run

  def send_cmd(s)
    puts "<"+s if @debug
    @iow.puts s
    @iow.flush
    @iow.puts "print '_end_of_cmd_'"
    @iow.flush
    @history << s
    res = []
    while line=@ior.gets
      puts ">"+line if @debug
      break if /^_end_of_cmd_$/ =~ line
      res << line
    end
    res # = res.chomp.strip
  end
  private :send_cmd

  def parse_plot_args(args)
    list = [[]]
    item = PlotItem.new
    list << item
    args.each do |arg|
      case arg
      when Range
        list.first << arg
      when Array
        if arg.all?{|e| e.kind_of?(Range)}
          list.first.concat(arg)
        elsif PlotItem.is_data(arg)
          item << arg
        else
          if list.last.empty?
            list.pop
          end
          item = PlotItem.new(*arg)
          list << item
        end
      when Hash
        item << arg
        item = PlotItem.new
        list << item
      else
        item << arg
      end
    end
    if list.last.empty?
      list.pop
    end
    return list
  end
  private :parse_plot_args


  # @private
  class OptsToS # :nodoc: all
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

  # @private
  class KvItem # :nodoc: all
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


  # @private
  class PlotItem # :nodoc: all

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
