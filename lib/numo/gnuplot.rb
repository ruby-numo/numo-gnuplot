module Numo

  def gnuplot(&block)
    if block
      Gnuplot.default.instance_eval(&block)
    else
      Gnuplot.default
    end
  end
  module_function :gnuplot

  def noteplot(&block)
    Gnuplot::NotePlot.new(&block)
  end
  module_function :noteplot

  class GnuplotError < StandardError; end

class Gnuplot

  VERSION = '0.2.4'
  POOL = []
  DATA_FORMAT = "%.7g"

  def self.default
    POOL[0] ||= self.new
  end

  class NotePlot

    def initialize(&block)
      raise ArgumentError, 'block is needed' if block.nil?

      @block = block
    end

    @@pool = nil

    def to_iruby
      require 'tempfile'
      tempfile_svg = Tempfile.open(['plot', '.svg'])
      # output SVG to tmpfile
      @@pool ||= Gnuplot.new(persist: false)
      gp = @@pool
      gp.reset
      gp.set terminal: 'svg'
      gp.set output: tempfile_svg.path
      gp.instance_eval(&@block)
      gp.unset 'output'
      svg = File.read(tempfile_svg.path)
      tempfile_svg.close
      ['image/svg+xml', svg]
    end
  end

  def initialize(path: 'gnuplot', persist: true)
    @path = path
    @persist = persist
    @history = []
    @debug = false
    r0, @iow = IO.pipe
    @ior, w2 = IO.pipe
    path += ' -persist' if persist
    IO.popen(path, :in => r0, :err => w2)
    r0.close
    w2.close
    @gnuplot_version = send_cmd("print GPVAL_VERSION")[0].chomp
    if /\.(\w+)$/ =~ (filename = ENV['NUMO_GNUPLOT_OUTPUT'])
      ext = $1
      ext = KNOWN_EXT[ext] || ext
      opts = ENV['NUMO_GNUPLOT_OPTION'] || ''
      set terminal: [ext, opts]
      set output: filename
    end
  end

  attr_reader :path
  attr_reader :persist
  attr_reader :history
  attr_reader :last_message
  attr_reader :gnuplot_version

  # draw 2D functions and data.
  def plot(*args)
    contents = parse_plot_args(PlotItem, args)
    _plot_splot('plot', contents)
    nil
  end

  # draws 2D projections of 3D surfaces and data.
  def splot(*args)
    contents = parse_plot_args(SPlotItem, args)
    _plot_splot('splot', contents)
    nil
  end

  def _plot_splot(cmd, contents)
    r = contents.shift.map { |x| "#{x} " }.join
    c = contents.map(&:cmd_str).join(', ')
    d = contents.map(&:data_str).join
    run "#{cmd} #{r}#{c}", d
    @last_data = d
    nil
  end
  private :_plot_splot

  # replot is not recommended, use refresh
  def replot(arg = nil)
    run "replot #{arg}", @last_data
    nil
  end

  # The `fit` command can fit a user-supplied expression to a set of
  # data points (x,z) or (x,y,z), using an implementation of the
  # nonlinear least-squares (NLLS) Marquardt-Levenberg algorithm.
  def fit(*args)
    range, items = parse_fit_args(args)
    r = range.map { |x| "#{x} " }.join
    c = items.cmd_str
    puts send_cmd("fit #{r}#{c}")
    nil
  end

  # This command writes the current values of the fit parameters into
  # the given file, formatted as an initial-value file (as described
  # in the `fit`section).  This is useful for saving the current
  # values for later use or for restarting a converged or stopped fit.
  def update(*filenames)
    puts send_cmd('update ' + filenames.map { |f| OptArg.quote(f) }.join(' '))
  end

  # This command prepares a statistical summary of the data in one or
  # two columns of a file.
  def stats(filename, *args)
    fn = OptArg.quote(filename)
    opt = OptArg.parse(*args)
    puts send_cmd "stats #{fn} #{opt}"
  end

  # The `set` command is used to set _lots_ of options.
  def set(*args)
    run "set #{OptArg.parse(*args)}"
    nil
  end

  # The `unset` command is used to return to their default state.
  def unset(*args)
    run "unset #{OptArg.parse(*args)}"
    nil
  end

  # The `help` command displays built-in help.
  def help(s = nil)
    puts send_cmd "help #{s}\n\n"
  end

  # The `show` command shows their settings.
  def show(*args)
    puts send_cmd "show #{OptArg.parse(*args)}"
  end

  #  The `reset` command causes all graph-related options that can be
  #  set with the `set` command to take on their default values.
  def reset(x = nil)
    run "reset #{x}"
    nil
  end

  # The `pause` command used to wait for events on window.
  # Carriage return entry (-1 is given for argument) and
  # text display option is disabled.
  #    pause 10
  #    pause 'mouse'
  #    pause mouse:%w[keypress button1 button2 button3 close any]
  def pause(*args)
    send_cmd("pause #{OptArg.parse(*args)}").join.chomp
    nil
  end

  # The `load` command executes each line of the specified input file.
  def load(filename)
    run "load #{OptArg.quote(filename)}"
    nil
  end

  alias kernel_raise :raise

  # The `raise` command raises plot window(s)
  def raise_plot(plot_window_nb=nil)
    send_cmd "raise #{plot_window_nb}"
    nil
  end
  alias raise :raise_plot

  # The `lower` command lowers plot window(s)
  def lower_plot(plot_window_nb=nil)
    send_cmd "lower #{plot_window_nb}"
    nil
  end
  alias lower :lower_plot

  # The `clear` command erases the current screen or output device as specified
  # by `set output`. This usually generates a formfeed on hardcopy devices.
  def clear
    send_cmd 'clear'
    nil
  end

  # The `exit` and `quit` commands will exit `gnuplot`.
  def exit
    send_cmd 'exit'
    nil
  end

  # The `exit` and `quit` commands will exit `gnuplot`.
  def quit
    send_cmd 'quit'
    nil
  end

  # The `refresh` reformats and redraws the current plot using the
  # data already read in.
  def refresh
    send_cmd 'refresh'
    nil
  end

  # `var` returns Gnuplot variable (not Gnuplot command)
  def var(name)
    res = send_cmd("print #{name}").join("").chomp
    if /undefined variable:/ =~ res
      kernel_raise GnuplotError, res.strip
    end
    res
  end

  KNOWN_EXT = { "ps" => "postscript", "jpg" => "jpeg" }

  # output current plot to file with terminal setting from extension
  # (not Gnuplot command)
  def output(filename, **opts)
    term = opts.delete(:term) || opts.delete(:terminal)
    if term.nil? && /\.(\w+)$/ =~ filename
      term = $1
    end
    term = KNOWN_EXT[term] || term
    if term.nil?
      kernel_raise GnuplotError, 'file extension is not given'
    end
    set :terminal, term, *opts
    set output: filename
    refresh
    unset :terminal
    unset :output
  end

  # turn on debug
  def debug_on
    @debug = true
  end

  # turn off debug
  def debug_off
    @debug = false
  end

  # send command-line string to Gnuplot directly
  def send(cmd)
    puts send_cmd(cmd)
  end

  #other_commands = %w[
  #  bind
  #  call
  #  cd
  #  do
  #  evaluate
  #  history
  #  if
  #  print
  #  pwd
  #  reread
  #  save
  #  shell
  #  system
  #  test
  #  while
  #]

  # for irb workspace name
  def to_s
    'gnuplot'
  end

  # private methods

  def run(s, data = nil)
    res = send_cmd(s, data)
    unless res.empty?
      if /.*?End\sof\sanimation\ssequence.*?/im =~ res.to_s
        return nil
      end

      if res.size < 7
        if /^\s*(line \d+: )?warning:/i =~ res[0]
          $stderr.puts res.join.strip
          return nil
        else
          msg = "\n" + res.join.strip
        end
      else
        msg = "\n" + res[0..5].join.strip + "\n :\n"
      end
      kernel_raise GnuplotError, msg
    end
    nil
  end

  def send_cmd(s,data=nil)
    if @debug
      puts '<' + s
      if data && !data.empty?
        if data.size > 144
          s1 = data[0..71]
          s2 = data[-72..-1]
          if s1.force_encoding("UTF-8").ascii_only? &&
              s2.force_encoding("UTF-8").ascii_only?
            a = [nil]*6
            if /\A(.+?)$(.+)?/m =~ s1
              a[0..1] = $1,$2
              if a[1] && /\A(.+?)?$(.+)?/m =~ a[1].strip
                a[1..2] = $1,$2
                a[1] = a[1]+"..." if !a[2]
              else
                a[0] = a[0]+"..."
              end
            end
            if /(.+)?^(.+?)\z/m =~ s2
              a[4..5] = $1,$2
              if a[4] && /(.+)?^(.+?)?\z/m =~ a[4].strip
                a[3..4] = $1,$2
                a[4] = "..."+a[4] if !a[3]
              else
                a[5] = "..."+a[5]
              end
            end
            if a[2] || a[3]
              a[2..3] = ["...",nil]
            end
            a.each{|l| puts "<"+l if l}
          else
            c = data[0..31].inspect
            c += "..." if data.size > 32
            puts "<"+c
          end
        else
          if data.force_encoding("UTF-8").ascii_only?
            data.split(/\n/).each{|l| puts "<"+l}
          else
            c = data[0..31].inspect
            c += "..." if data.size > 32
            puts "<"+c
          end
        end
      end
    end
    @iow.puts s
    @iow.puts data
    @iow.flush
    @iow.puts "print '_end_of_cmd_'"
    @iow.flush
    @history << s
    @last_message = []
    while (line = @ior.gets)
      break if /^_end_of_cmd_$/ =~ line.chomp

      puts '>' + line if @debug
      @last_message << line
    end
    @last_message
  end

  private :send_cmd

  def parse_plot_args(cPlotItem,args)
    range = []
    while !args.empty?
      case a = args.first
      when Range
        range << range_to_s(args.shift)
      when String
        if /^\[.*\]$/ =~ a
          range << args.shift
        else
          break
        end
      else
        break
      end
    end
    item = cPlotItem.new # first item is range
    list = [range,item]
    args.each do |arg|
      case arg
      when Range
        list.first << range_to_s(arg)
      when Array
        if arg.all?{|e| e.kind_of?(Range)}
          arg.each{|e| list.first << range_to_s(e)}
        elsif PlotItem.is_data(arg)
          item << arg
        else
          list.pop if list.last.empty?
          list << item = cPlotItem.new(*arg) # next PlotItem
        end
      when Hash
        item << arg
        list << item = cPlotItem.new # next PlotItem
      when String
        list.pop if list.last.empty?
        list << item = cPlotItem.new(arg) # next PlotItem
      else
        item << arg
      end
    end
    list.pop if list.last.empty?
    return list
  end
  private :parse_plot_args

  def range_to_s(*a)
    case a.size
    when 1
      a = a[0]
      "[#{a.first}:#{a.last}]"
    when 2
      "[#{a[0]}:#{a[1]}]"
    else
      kernel_raise ArgumentError,"wrong number of argument"
    end
  end
  private :range_to_s

  def parse_fit_args(args)
    range = []
    while !args.empty?
      case a = args.first
      when Range
        range << range_to_s(args.shift)
      when String
        if /^\[.*\]$/ =~ a
          range << args.shift
        else
          break
        end
      else
        break
      end
    end
    items = FitItem.new(args.shift, args.shift)
    args.each do |arg|
      case arg
      when Range
        range << range_to_s(arg)
      when Array
        if arg.all?{|e| e.kind_of?(Range)}
          arg.each{|e| range << range_to_s(e)}
        else
          items << arg
        end
      else
        items << arg
      end
    end
    return [range,items]
  end
  private :parse_fit_args


  # @private
  module OptArg # :nodoc: all

    module_function

    def from_symbol(s)
      s = s.to_s
      if /^(.*)_(noquote|nq)$/ =~ s
        s = $1
      end
      s.tr('_',' ')
    end

    def parse(*opts)
      sep = ','
      a = []
      while (opt = opts.shift)
        sep = ' ' unless opt.is_a?(Numeric)
        case opt
        when Symbol
          a << from_symbol(opt)
          case opt
          when :label
            a << opts.shift.to_s if opts.first.kind_of?(Integer)
            a << OptArg.quote(opts.shift) if opts.first.kind_of?(String)
          when NEED_QUOTE_TIME
            a << OptArg.quote_time(opts.shift) if opts.first.kind_of?(String)
          when NEED_QUOTE
            a << OptArg.quote(opts.shift) if opts.first.kind_of?(String)
          end
        when Array
          a << parse(*opt)
        when Hash
          a << opt.map { |k, v| parse_kv(k, v) }.compact.join(' ')
        when Range
          a << "[#{opt.begin}:#{opt.end}]"
        else
          a << opt.to_s
        end
      end
      a.join(sep)
    end

    NEED_QUOTE_TIME = /^timef(mt?)?/

    def quote_time(s)
      "'#{s}'"
    end

    NEED_QUOTE = %w[
      background
      cblabel
      clabel
      commentschars
      dashtype
      decimalsign
      file
      fontpath
      format
      locale
      logfile
      missing
      name
      newhistogram
      output
      prefix
      print
      rgb
      separator
      table
      timefmt
      title
      x2label
      xlabel
      y2label
      ylabel
      zlabel
      xy
    ]
    NONEED_QUOTE = %w[
      for
      log
      smooth
    ]

    def NEED_QUOTE.===(k)
      k = $1 if /_([^_]+)$/ =~ k
      re = /^#{k}/
      return false if NONEED_QUOTE.any?{|q| re =~ q}
      any?{|q| re =~ q}
    end

    def quote(s)
      case s
      when /^('.*'|".*")$/
        s
      when String
        s.inspect
      else
        s
      end
    end

    def parse_kv(s,v)
      k = from_symbol(s)
      case s.to_s
      when /^at(_.*)?$/
        case v
        when String
          "#{k} #{v}" # not quote
        when Array
          "#{k} #{v.map{|x| x.to_s}.join(",")}"
        else
          "#{k} #{parse(v)}"
        end
      when "label"
        case v
        when String
          "#{k} #{OptArg.quote(v)}"
        when Array
          if v[0].kind_of?(Integer) && v[1].kind_of?(String)
            "#{k} #{parse(v[0],OptArg.quote(v[1]),*v[2..-1])}"
          elsif v[0].kind_of?(String)
            "#{k} #{parse(OptArg.quote(v[0]),*v[1..-1])}"
          else
            "#{k} #{parse(*v)}"
          end
        when TrueClass
          k
        else
          "#{k} #{parse(v)}"
        end
      when NEED_QUOTE_TIME
        "#{k} #{OptArg.quote_time(v)}"
      when NEED_QUOTE
        case v
        when String
          "#{k} #{OptArg.quote(v)}"
        when TrueClass
          k
        when NilClass
          nil
        when FalseClass
          nil
        when Array
          case v[0]
          when String
            if v.size == 1
              "#{k} #{OptArg.quote(v[0])}"
            else
              "#{k} #{OptArg.quote(v[0])} #{parse(*v[1..-1])}"
            end
          else
            "#{k} #{parse(*v)}"
          end
        else
          "#{k} #{parse(v)}"
        end
      else
        case v
        when String
          "#{k} #{v}"
        when TrueClass
          k
        when NilClass
          nil
        when FalseClass
          nil
        when Array
          re = /^#{k}/
          if re =~ "using" || re =~ "every"
            "#{k} #{v.join(':')}"
          elsif v.empty?
            k
          else
            "#{k} #{parse(*v)}"
          end
        else
          "#{k} #{parse(v)}"
        end
      end
    end

  end # OptArg


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
      end
      if defined?(Numo::NArray)
        return true if a.kind_of?(Numo::NArray)
      end
      if defined?(::NArray)
        return true if a.kind_of?(::NArray)
      end
      if defined?(::NMatrix)
        return true if a.kind_of?(::NMatrix)
      end
      case a[a.size-1] # quick check for unknown data class
      when Numeric
        return true if a[0].kind_of?(Numeric)
      when String
        return true if a[0].kind_of?(String)
      end
      false
    rescue
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
        elsif @items.first.kind_of?(String) || @items.first.kind_of?(Symbol)
          @function = @items.first
          @options = @items[1..-1]
          if (o=@items.last).kind_of? Hash
            if o.any?{|k,v| /^#{k}/ =~ "using"}
              # @function is data file
              @function = OptArg.quote(@function)
            end
          end
        else
          data = []
          @options = []
          @items.each do |x|
            if PlotItem.is_data(x)
              data << x
            else
              @options << x
              if x.kind_of? Hash
                x.each do |k,v|
                  if /^#{k}/ =~ "with"
                    @style = v; break;
                  end
                end
              end
            end
          end
          if data.empty?
            @function = ''
          else
            @data = parse_data(data)
          end
        end
      end
    end

    def parse_data_style(data)
      if @style
        re = /^#{@style}/
        if re =~ "image"
          return ImageData.new(*data)
        elsif re =~ "rgbimage"
          return RgbImageData.new(*data)
        elsif re =~ "rgbalpha"
          return RgbAlphaData.new(*data)
        end
      end
    end

    def parse_data(data)
      parse_data_style(data) || PlotData.new(*data)
    end

    def cmd_str
      parse_items
      if @function
        "%s %s" % [@function, OptArg.parse(*@options)]
      else
        "%s %s" % [@data.cmd_str, OptArg.parse(*@options)]
      end
    end

    def data_str
      parse_items
      if @function
        nil
      else
        @data.data_str
      end
    end

  end # PlotItem


  # @private
  class FitItem # :nodoc: all
    def initialize(expression,datafile)
      @expression = expression
      @datafile = datafile
      @items = []
    end

    def <<(item)
      @items << item
    end

    def empty?
      @items.empty?
    end

    def cmd_str
      "%s %s %s" % [@expression, OptArg.quote(@datafile), OptArg.parse(*@items)]
    end
  end

  # @private
  class SPlotItem < PlotItem  # :nodoc: all
    def parse_data(data)
      parse_data_style(data) ||
        (data.size == 1) ?
        ImageData.new(data.first) :
        SPlotRecord.new(*data)
    end
  end


  # @private
  class PlotData  # :nodoc: all

    def initialize(*data)
      if data.empty?
        raise ArgumentError,"no data"
      end
      @data = data.map{|a| a.respond_to?(:flatten) ? a.flatten : a}
      @n = @data.map{|a| a.size}.min
      @text = true
    end

    def cmd_str
      if @text
        "'-'"
      else
        "'-' binary record=#{@n} format='%float64'"
      end
    end

    def as_array(a)
      case a
      when Numo::NArray,Array
        a
      else
        a.to_a
      end
    end

    def data_str
      if @text
        s = ""
        @n.times{|i| s << line_str(i)+"\n"}
        s + "e\n"
      elsif defined? Numo::NArray
        m = @data.size
        x = Numo::DFloat.zeros(@n,m)
        m.times{|i| x[true,i] = as_array(@data[i])[0...@n]}
        x.to_string
      else
        s = []
        @n.times{|i| s.concat @data.map{|a| a[i]}}
        s.pack("d*")
      end
    end

    def line_str(i)
      @data.map do |a|
        PlotData.quote_data(a[i])
      end.join(" ")
    end

    def self.quote_data(v)
      case v
      when Float,Rational
        DATA_FORMAT % v
      when Numeric
        v.to_s
      else
        s = v.to_s.gsub(/\n/,'\n')
        if /^(e|.*[ \t].*)$/ =~ s
          if /"/ =~ s
            raise GnuplotError,"Datastrings cannot include"+
              " double quotation and space simultaneously"
          end
          s = '"'+s+'"'
        end
        s
      end
    end

    def self.array_shape(a)
      if a.kind_of?(Array)
        is_2d = true
        is_1d = true
        size_min = nil
        a.each do |b|
          if b.kind_of?(Array)
            is_1d = false
            if b.any?{|c| c.kind_of?(Array)}
              is_2d = false
            elsif size_min.nil? || b.size < size_min
              size_min = b.size
            end
          else
            is_2d = false
          end
          break if !is_1d && !is_2d
        end
        if is_1d
          [a.size]
        elsif is_2d
          [a.size, size_min]
        else
          raise GnuplotError, "not suitable Array for data"
        end
      elsif a.respond_to?(:shape)
        a.shape
      elsif PlotItem.is_data(a)
        [a.size]
      else
        raise GnuplotError, "not suitable type for data"
      end
    end
  end

  # @private
  class SPlotRecord < PlotData  # :nodoc: all

    def initialize(x,y,z)
      @text = false
      @data = [x,y,z].map{|a| a.respond_to?(:flatten) ? a.flatten : a}
      @n = @data.map{|a| a.size}.min
      shape = PlotData.array_shape(@data[2])
      if shape.size >= 2
        n = shape[1]*shape[0]
        if @n < n
          raise GnuplotError, "data size mismatch"
        end
        @n = n
        @record = "#{shape[1]},#{shape[0]}"
      else
        @record = "#{@n}"
      end
    end

    def cmd_str
      if @text
        "'-'"
      else
        "'-' binary record=(#{@record}) format='%float64' using 1:2:3"
      end
    end
  end

  # @private
  class ImageData < PlotData  # :nodoc: all

    def check_shape
      if @data.shape.size != 2
        raise IndexError,"array should be 2-dimensional"
      end
      @shape = @data.shape
    end

    def initialize(data)
      @text = false
      if data.respond_to?(:shape)
        @data = data
        check_shape
        if defined? Numo::NArray
          @format =
            case @data
            when Numo::DFloat; "%float64"
            when Numo::SFloat; "%float32"
            when Numo::Int8;   "%int8"
            when Numo::UInt8;  "%uint8"
            when Numo::Int16;  "%int16"
            when Numo::UInt16; "%uint16"
            when Numo::Int32;  "%int32"
            when Numo::UInt32; "%uint32"
            when Numo::Int64;  "%int64"
            when Numo::UInt64; "%uint64"
            else
              raise ArgumentError,"not supported NArray type"
            end
        end
      elsif data.kind_of? Array
        n = nil
        @data = []
        data.each do |a|
          @data.concat(a)
          m = a.size
          if n && n != m
            raise IndexError,"element size differs (%d should be %d)"%[m, n]
          end
          n = m
        end
        @shape = [data.size,n]
        @format = "%float64"
      else
        raise ArgumentError,"argument should be data array"
      end
    end

    def cmd_str
      if @text
        "'-' matrix"
      else
        "'-' binary array=(#{@shape[1]},#{@shape[0]}) format='#{@format}'"
      end
    end

    def data_str
      if @text
        f = DATA_FORMAT
        s = ''
        @data.to_a.each do |b|
          s << b.map { |e| f % e }.join(' ') + "\n"
        end
        s + "\ne"
      elsif defined? Numo::NArray && @data.is_a?(Numo::NArray)
        @data.to_string
      elsif @data.is_a?(Array)
        @data.pack("d*")
      elsif @data.repond_to?(:to_a)
        @data.to_a.pack("d*")
      else
        raise TypeError, "invalid data type: #{@data.class}"
      end
    end
  end

  # @private
  class RgbImageData < ImageData  # :nodoc: all

    def initialize(data)
      if data.is_a?(Numo::NArray)
        super(data)
      else
        super(Numo::NArray[*data])
      end
    end

    def check_shape
      if @data.shape.size != 3
        raise IndexError, 'array should be 2-dimensional'
      end
      if @data.shape[2] != 3
        raise IndexError, 'shape[2] (last dimension size) must be 3'
      end
      @shape = @data.shape
    end
  end

  # @private
  class RgbAlphaData < ImageData # :nodoc: all

    def initialize(data)
      if data.is_a?(Numo::NArray)
        super(data)
      else
        super(Numo::NArray[*data])
      end
    end

    def check_shape
      if @data.shape.size != 3
        raise IndexError, 'array should be 2-dimensional'
      end
      if @data.shape[2] != 4
        raise IndexError, 'shape[2] (last dimension size) must be 4'
      end
      @shape = @data.shape
    end
  end

end # Numo::Gnuplot
end
