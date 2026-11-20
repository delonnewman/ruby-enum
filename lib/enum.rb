class Union
  class << self
    def new(...)
      raise NoMethodError if self == Enum
      super(...)
    end

    def indexes
      @indexes ||= { name: {} }
    end

    def index_by(*methods)
      methods.each do |method| 
        indexes[method] = {}
      end
    end

    def members
      indexes[:name].values
    end
    
    def names
      indexes[:name].keys
    end

    def named(name)
      indexes[:name].fetch(name)
    end

    def coerce(value)
      return value if value.is_a?(self)

      indexes.each_pair do |key, index| 
        member = index[value]
        return member unless member.nil?
      end

      raise TypeError, "invalid #{self} value: #{value.inspect}"
    end
    alias [] coerce
  end

  attr_reader :name

  def initialize(name)
    @name  = name
    freeze
  end

  def to_s = @name.to_s
    
  def inspect
    "#<union #{self.class.superclass} #{@name}>"
  end

  def self.define(*members, &block)
    Class.new(self) do
      members.each do |name|
        member_class = Class.new(self)
        class_name   = name.to_s.capitalize
        const_set(class_name, member_class) unless const_defined?(class_name, false)

        member = member_class.new(name)
        define_singleton_method(name) { member }
      end

      class_eval(&block) if block

      # build indexes
      members.each do |name| 
        member = public_send(name)
        indexes.keys.each do |key| 
          indexes[key][member.public_send(key)] = member
        end
      end
    end
  end
end

class Enum < Union
  class << self
    def indexes
      @indexes ||= { name: {}, value: {} }
    end

    def of(value)
      indexes[:value].fetch(value)
    end
  end
  
  attr_reader :value

  def initialize(name, value)
    @value = value
    super(name)
    freeze
  end

  def to_i = @value.to_i
  def to_r = @value.to_r
  def to_f = @value.to_f
    
  def inspect
    "#<enum #{self.class.superclass} #{name}=#{@value}>"
  end

  def self.define(*members, &block)
    Class.new(self) do
      members.each_with_index do |name, value|
        member_class = Class.new(self)
        class_name   = name.to_s.capitalize
        const_set(class_name, member_class) unless const_defined?(class_name, false)

        member = member_class.new(name, value)
        define_singleton_method(name) { member }
      end

      class_eval(&block) if block

      # build indexes
      members.each do |name| 
        member = public_send(name)
        indexes.keys.each do |key| 
          indexes[key][member.public_send(key)] = member
        end
      end
    end
  end
end

Unit = Union.define(:meters, :kilometers, :centimeters, :millimeters, :decimeters) do 
  index_by :abbreviation
  
  def abbreviation
    raise NoMethodError
  end

  def conversion_ratio
    raise NoMethodError
  end

  def to_s
    abbreviation.to_s
  end

  class self::Meters
    def abbreviation = :m
    def conversion_ratio = 1r
  end

  class self::Kilometers
    def abbreviation = :km
    def conversion_ratio = 1/1000r
  end

  class self::Decimeters
    def abbreviation = :dm
    def conversion_ratio = 1/10r
  end

  class self::Centimeters
    def abbreviation = :cm
    def conversion_ratio = 100r
  end

  class self::Millimeters
    def abbreviation = :mm
    def conversion_ratio = 1000r
  end
end

Measure = Data.define(:amount, :unit) do
  def initialize(amount:, unit: :meters)
    super(amount:, unit: Unit.coerce(unit))
  end

  def in(unit)
    u = Unit.coerce(unit)
    Measure[in_meters * u.conversion_ratio, u]
  end
  alias >> in

  def in_meters
    amount / unit.conversion_ratio
  end

  def to_s
    "#{amount} #{unit}"
  end
  alias inspect to_s
end

Measure[5, :km] >> :m

