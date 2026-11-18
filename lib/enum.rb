class Enum
  def self.define(*members, &)
    enum = Class.new(Enum, &)

    member_class = Class.new(enum) do
      attr_reader :name, :value
      def initialize(name, value)
        @name  = name
        @value = value
        freeze
      end

      def inspect
        "#<enum #{self.class.superclass} #{@name}=#{@value}>"
      end
      alias to_s inspect
    end

    enum.instance_eval do
      def members_by_name
        @members_by_name ||= {}
      end

      def members_by_value
        @members_by_value ||= {}
      end

      members.each_with_index do |name, value|
        member = member_class.new(name, value)
        const_set(name.to_s.capitalize, member)
        members_by_name[name] = member
        members_by_value[value] = member
      end

      def new(...)
        raise NoMethodError
      end

      def members
        members_by_name.keys
      end

      def named(name)
        members_by_name.fetch(name)
      end

      def of(value)
        members_by_value.fetch(value)
      end

      members.each do |name|
        define_singleton_method name do
          members_by_name[name]
        end
      end
    end

    enum
  end
end

Unit = Enum.define(:meters, :kilometers, :centimeters, :millimeters, :decimeters) do
  def conversion_ratio
    raise NoMethodError
  end
end

Measure = Data.define(:amount, :unit) do
  def convert(unit)
    amount * unit.conversion_ratio
  end
end

class Unit
  class << self
    alias m meters
    alias km kilometers
    alias cm centimeters
    alias dm decimeters
    alias mm millimeters
  end
end

class Unit::Meters
  def conversion_ratio
    0
  end
end

class Unit::Kilometers
  def conversion_ratio
    1/1000r
  end
end

class Unit::Decimeters
  def conversion_ratio
    1/10r
  end
end

class Unit::Centimeters
  def conversion_ratio
    100
  end
end

class Unit::Millimeters
  def conversion_ratio
    1000
  end
end
