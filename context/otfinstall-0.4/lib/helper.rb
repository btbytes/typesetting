# helper rb for dsl

class Module
  def dsl_accessor(*symbols)
    symbols.each { |sym|
      class_eval %{
        def #{sym}(*val)
          if val.empty?
            @#{sym}
          else
            @#{sym} = val.size == 1 ? val[0] : val
          end
        end
      }
    }
  end
end

class BlankSlate
  instance_methods.each { |m| undef_method(m) unless %w(
       __send__ __id__ send class 
      inspect instance_eval instance_variables instance_variable_get
       ).include?(m)
  }
end #class BlankSlate

class OInst  < BlankSlate
  def method_missing(sym, *args)
    self.class.dsl_accessor sym
    send(sym, *args)
  end
  def self.load(filename)
    dsl = new
    dsl.instance_eval(File.read(filename).gsub(/#*$/,''), filename)
    dsl
  end
end # class DSL

