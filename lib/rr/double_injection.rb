module RR
  # RR::DoubleInjection is the binding of an object and a method.
  # A double_injection has 0 to many Double objects. Each Double
  # has Argument Expectations and Times called Expectations.
  class DoubleInjection
    MethodArguments = Struct.new(:arguments, :block)
    attr_reader :object, :method_name, :doubles

    def initialize(object, method_name)
      @object = object
      @method_name = method_name.to_sym
      if object_has_method?(method_name)
        begin
          meta.__send__(:alias_method, original_method_name, method_name)
        rescue NameError => e
          object.send(method_name)
          meta.__send__(:alias_method, original_method_name, method_name)
        end
      end
      @doubles = []
    end

    # RR::DoubleInjection#register_double adds the passed in Double
    # into this DoubleInjection's list of Double objects.
    def register_double(double)
      @doubles << double
    end

    # RR::DoubleInjection#bind injects a method that acts as a dispatcher
    # that dispatches to the matching Double when the method
    # is called.
    def bind
      define_implementation_placeholder
      returns_method = <<-METHOD
        def #{@method_name}(*args, &block)
          arguments = MethodArguments.new(args, block)
          __send__('#{placeholder_name}', arguments)
        end
      METHOD
      meta.class_eval(returns_method, __FILE__, __LINE__ - 5)
    end

    # RR::DoubleInjection#verify verifies each Double
    # TimesCalledExpectation are met.
    def verify
      @doubles.each do |double|
        double.verify
      end
    end

    # RR::DoubleInjection#reset removes the injected dispatcher method.
    # It binds the original method implementation on the object
    # if one exists.
    def reset
      meta.__send__(:remove_method, placeholder_name)
      if object_has_original_method?
        meta.__send__(:alias_method, @method_name, original_method_name)
        meta.__send__(:remove_method, original_method_name)
      else
        meta.__send__(:remove_method, @method_name)
      end
    end

    def call_original_method(*args, &block)
      @object.__send__(original_method_name, *args, &block)
    end

    def object_has_original_method?
      object_has_method?(original_method_name)
    end

    protected
    def define_implementation_placeholder
      me = self
      meta.__send__(:define_method, placeholder_name) do |arguments|
        me.__send__(:call_method, arguments.arguments, arguments.block)
      end
    end

    def call_method(args, block)
      if double = find_double_to_attempt(args)
        return double.call(self, *args, &block)
      end
      double_not_found_error(*args)
    end

    def find_double_to_attempt(args)
      matches = DoubleMatches.new(@doubles).find_all_matches(args)

      unless matches.exact_terminal_doubles_to_attempt.empty?
        return matches.exact_terminal_doubles_to_attempt.first
      end

      unless matches.exact_non_terminal_doubles_to_attempt.empty?
        return matches.exact_non_terminal_doubles_to_attempt.last
      end

      unless matches.wildcard_terminal_doubles_to_attempt.empty?
        return matches.wildcard_terminal_doubles_to_attempt.first
      end

      unless matches.wildcard_non_terminal_doubles_to_attempt.empty?
        return matches.wildcard_non_terminal_doubles_to_attempt.last
      end

      unless matches.matching_doubles.empty?
        # This will raise a TimesCalledError
        return matches.matching_doubles.first
      end

      return nil
    end

    def double_not_found_error(*args)
      message = "On object #{object},\n"
      message << "unexpected method invocation in the next line followed by the expected invocations\n"
      message << "  #{Double.formatted_name(@method_name, args)}\n"
      message << Double.list_message_part(@doubles)
      raise Errors::DoubleNotFoundError, message
    end

    def placeholder_name
      "__rr__#{@method_name}"
    end

    def original_method_name
      "__rr__original_#{@method_name}"
    end

    def object_has_method?(method_name)
      @object.methods.include?(method_name.to_s) || @object.respond_to?(method_name)
    end

    def meta
      (class << @object; self; end)
    end
  end
end