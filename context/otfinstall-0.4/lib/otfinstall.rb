
require "fileutils"

require_relative "helper"


class OTFInstall
  attr_accessor :vendor
  attr_accessor :collection
  attr_accessor :basedir
  attr_accessor :updmap
  # if set, the otf will be found in vendor/collection
  attr_accessor :fontbase
  def initialize
    @collection = nil
    @vendor = nil
    @updmap = false
    @basedir = nil
    @args = []
    @maplines = []
    @fontbase = nil
    @typescript={}
    @typescript[:map]  = []
    @typescript[:name] = []
    @typescript[:enc]  = []
    @typescript[:font] = []
  end
  def check_info
    raise "collection not set" unless @collection
    raise "vendor not set" unless @vendor
    raise "basedir not set" unless @basedir
  end
  def install
    @args=[]
    @args << "--tfm-directory=#{dir :tfm}"
    @args << "--vf-directory=#{dir :vf}"
    @args << "--pl-directory=#{dir :pl}"
    @args << "--vpl-directory=#{dir :vpl}"
    @args << "--encoding-directory=#{dir :enc}"
    @args << "--type1-directory=#{dir :t1}"
    @args << "--truetype-directory=#{dir :truetype}"
    @args << "--no-updmap"
    @args << "--encoding=texnansi"
    @args
  end

  def dir(what)
    check_info
    case what
    when :ctx
      FileUtils::mkdir_p "#{@basedir}/tex/context/typescripts"
      "#{@basedir}/tex/context/typescripts/type-#{collection}.tex"
    when :tfm
      FileUtils::mkdir_p "#{@basedir}/fonts/tfm/#{@vendor}/#{@collection}"
    when :vf
      FileUtils::mkdir_p "#{@basedir}/fonts/vf/#{@vendor}/#{@collection}"
    when :pl
      FileUtils::mkdir_p "#{@basedir}/fonts/pl/#{@vendor}/#{@collection}"
    when :vpl
      FileUtils::mkdir_p "#{@basedir}/fonts/vpl/#{@vendor}/#{@collection}"
    when :enc
      FileUtils::mkdir_p "#{@basedir}/fonts/enc/dvips/#{@vendor}"
    when :t1
      FileUtils::mkdir_p "#{@basedir}/fonts/type1/#{@vendor}/#{@collection}"
    when :truetype
      FileUtils::mkdir_p "#{@basedir}/fonts/truetype/#{@vendor}/#{@collection}"
    when :map
      FileUtils::mkdir_p "#{@basedir}/fonts/map/pdftex"
      "#{@basedir}/fonts/map/pdftex/#{@collection}.map"
    when :example
      FileUtils::mkdir_p "#{@basedir}/tex/context/example"
      "#{@basedir}/tex/context/example/#{@collection}.tex"
    else
      raise
    end
  end
  
  def set_default_value(value,default,warn=true)
    x = if @otfinstr.instance_variables.member?("@#{value}")
      @otfinstr.instance_variable_get("@#{value}")
    else
      puts "warning: #{value} not set, using #{default.inspect}" if warn
      default
    end
    self.instance_variable_set("@#{value}",x)
  end

  # features are an array of fontfeatures
  def install_font(fontfile,weight,features)
    unless test(?f,fontfile)
      puts "Cannot find fontfile `#{fontfile}'"
      exit(-1)
    end
    psname=`otfinfo -p #{fontfile}`.chomp
    features.each do |feature_ctx,otftotfm_instruction|
      @typescript[:name] << " \\definefontsynonym  [#{@fontclass.capitalize}#{weight}#{feature_ctx}] [#{psname}#{feature_ctx}]"
    end
    
    features.each do |feature_ctx,otftotfm_instruction|
      puts "Preparing #{fontfile} with features: #{feature_ctx}"
      args = install <<  fontfile
      args << "-fliga"
      args << "-fkern"
      args << otftotfm_instruction
      mapline = `otftotfm #{args.join(" ")}  2>otfinstall.log`.chomp
      @typescript[:enc] << sprintf(" \\definefontsynonym %-30s %-30s [encoding=texnansi]","[#{psname}#{feature_ctx}]","[#{get_tex_name(mapline)}]")
      @maplines << mapline
    end
  end
  
  def collect_typescripts
    tmp = []
    tmp << "\\starttypescript [map] [#{@collection}] [texnansi]"
    tmp << @typescript[:map].join("\n")
    tmp << "\\stoptypescript"

    tmp << "\\starttypescript [#{@fontclass}] [#{@collection}] [name]"
    tmp << @typescript[:name].join("\n")
    tmp << "\\stoptypescript"

    tmp << "\\starttypescript [#{@fontclass}] [#{@collection}] [texnansi]"
    tmp << @typescript[:enc].join("\n")
    tmp << "\\stoptypescript"

    tmp << "\\starttypescript [#{@collection}]"
    tmp << @typescript[:font].join("\n")
    tmp << "\\stoptypescript"

    return tmp.join("\n")
  end
  
  def read_otfinstr(path)
    @otfinstr=OInst.load(path)
    
    # set some default values
    set_default_value("collection","otfinstall")
    set_default_value("fontclass" ,"serif")
    set_default_value("vendor",    "otfinstall")
    set_default_value("variants",  ["default"] )
    
    fontdir = @fontbase ? File.join(@fontbase,vendor,collection) : ""
    if tmp = @otfinstr.instance_variable_get("@regular") then
      rg=File.join(fontdir,tmp)
    end
    if tmp = @otfinstr.instance_variable_get("@bold")
      bo=File.join(fontdir,tmp)
    end
    if tmp = @otfinstr.instance_variable_get("@italic")
      it=File.join(fontdir,tmp)
    end
    if tmp = @otfinstr.instance_variable_get("@bolditalic")
      bi=File.join(fontdir, tmp)
    end

    @maplines=[]
    
    @variants.each do |variant|
      case variant 
      when "default"
        instr=[["",""],["Caps","-fsmcp"]]
        install_font(rg,"",instr)           if rg
        install_font(bo,"Bold",instr)       if bo
        install_font(it,"Italic",instr)     if it
        install_font(bi,"BoldItalic",instr) if bi
      when "osf"
        instr=[["OsF","-fonum"]]
        install_font(rg,"Regular",instr)    if rg
        install_font(bo,"Bold",instr)       if bo
        install_font(it,"Italic",instr)     if it
        install_font(bi,"BoldItalic",instr) if bi
        @typescript[:name] << " \\definefontvariant  [#{@fontclass.capitalize}][osf][OsF]"
      else
        raise "not implemented variant"
      end
    end
    @typescript[:name] << " \\definefontsynonym  [#{@fontclass.capitalize}Regular]       [#{@fontclass.capitalize}]"
    @typescript[:map] = [" \\loadmapfile [#{@collection}.map]"]
    @typescript[:font] = ["\\definetypeface [#{@collection}][rm][#{@fontclass}] [#{@collection}][default][encoding=texnansi]"]

    File.open(dir(:map),"w") do |f|
      f << @maplines.join("\n")
    end
    File.open(dir(:ctx),"w") do |f|
      f << collect_typescripts
    end
    File.open(dir(:example),"w") do |f|
      f << write_sample
    end
  end
  
  private
  def write_sample
    tmp=""
    tmp << "\\preloadtypescripts\n"
    tmp << "\\setupencoding[default=texnansi]\n"
    tmp << "\\usetypescriptfile[type-#{@collection}]\n"
    tmp << "\\usetypescript[#{@collection}]\n"

    tmp << "\\definetypeface [sample][rm][serif][#{@collection}][default][encoding=texnansi]\n"

    tmp << "\\definebodyfontenvironment [#{@collection}][14pt][interlinespace=20pt]\n"
    tmp << "\\setupbodyfont[sample,#{@fontclass},14pt]\n"

    tmp << "\\enableregime[utf-8]\n"
    tmp << "\\setuptolerance [tolerant]\n" 
    tmp << "\\starttext\n"
    tmp << "\\input tufte\n"
    tmp << "\\stoptext\n"
  end
  
  def get_tex_name(mapline)
    # the tex relevant name is the first part in the mapline
    mapline.split[0].chomp('--base')
  end
end
