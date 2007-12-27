require "spec/spec_helper"

module RR
describe Space, "#reset" do
  it_should_behave_like "RR::Space"

  before do
    @space = Space.new
    @object1 = Object.new
    @object2 = Object.new
    @method_name = :foobar
  end

  it "removes the ordered scenarios" do
    double1 = @space.double(@object1, :foobar1)
    double2 = @space.double(@object1, :foobar2)

    scenario1 = @space.scenario(double1)
    scenario2 = @space.scenario(double2)

    scenario1.ordered
    scenario2.ordered

    @space.ordered_scenarios.should_not be_empty

    @space.reset
    @space.ordered_scenarios.should be_empty
  end

  it "resets all doubles" do
    double1 = @space.double(@object1, @method_name)
    double1_reset_calls = 0
    (class << double1; self; end).class_eval do
      define_method(:reset) do ||
        double1_reset_calls += 1
      end
    end
    double2 = @space.double(@object2, @method_name)
    double2_reset_calls = 0
    (class << double2; self; end).class_eval do
      define_method(:reset) do ||
        double2_reset_calls += 1
      end
    end

    @space.reset
    double1_reset_calls.should == 1
    double2_reset_calls.should == 1
  end
end

describe Space, "#reset_double" do
  it_should_behave_like "RR::Space"

  before do
    @space = Space.new
    @object = Object.new
    @method_name = :foobar
  end

  it "resets the doubles" do
    double = @space.double(@object, @method_name)
    @space.doubles[@object][@method_name].should === double
    @object.methods.should include("__rr__#{@method_name}")

    @space.reset_double(@object, @method_name)
    @space.doubles[@object][@method_name].should be_nil
    @object.methods.should_not include("__rr__#{@method_name}")
  end

  it "removes the object from the doubles map when it has no doubles" do
    double1 = @space.double(@object, :foobar1)
    double2 = @space.double(@object, :foobar2)

    @space.doubles.include?(@object).should == true
    @space.doubles[@object][:foobar1].should_not be_nil
    @space.doubles[@object][:foobar2].should_not be_nil

    @space.reset_double(@object, :foobar1)
    @space.doubles.include?(@object).should == true
    @space.doubles[@object][:foobar1].should be_nil
    @space.doubles[@object][:foobar2].should_not be_nil

    @space.reset_double(@object, :foobar2)
    @space.doubles.include?(@object).should == false
  end
end

describe Space, "#reset_doubles" do
  it_should_behave_like "RR::Space"

  before do
    @space = Space.new
    @object1 = Object.new
    @object2 = Object.new
    @method_name = :foobar
  end

  it "resets the double and removes it from the doubles list" do
    double1 = @space.double(@object1, @method_name)
    double1_reset_calls = 0
    (class << double1; self; end).class_eval do
      define_method(:reset) do ||
        double1_reset_calls += 1
      end
    end
    double2 = @space.double(@object2, @method_name)
    double2_reset_calls = 0
    (class << double2; self; end).class_eval do
      define_method(:reset) do ||
        double2_reset_calls += 1
      end
    end

    @space.send(:reset_doubles)
    double1_reset_calls.should == 1
    double2_reset_calls.should == 1
  end
end
end