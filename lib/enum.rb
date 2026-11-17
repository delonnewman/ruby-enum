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
