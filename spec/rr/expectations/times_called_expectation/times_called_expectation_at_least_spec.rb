require "spec/spec_helper"

module RR
module Expectations
  describe TimesCalledExpectation, ' with AtLeastMatcher' do
    it_should_behave_like "RR::Expectations::TimesCalledExpectation"
    attr_reader :times, :at_least
    
    before do
      @times = 3
      @at_least = TimesCalledMatchers::AtLeastMatcher.new(times)
      @expectation = TimesCalledExpectation.new(double, at_least)
    end
    
    describe "#verify!" do
      it "passes when times called > times" do
        4.times {expectation.attempt}
        expectation.verify!
      end

      it "passes when times called == times" do
        3.times {expectation.attempt}
        expectation.verify!
      end

      it "raises error when times called < times" do
        expectation.attempt
        lambda do
          expectation.verify!
        end.should raise_error(
        RR::Errors::TimesCalledError,
        "foobar()\nCalled 1 time.\nExpected at least 3 times."
        )
      end
    end

    describe "#attempt?" do
      it "always returns true" do
        expectation.should be_attempt
        10.times {expectation.attempt}
        expectation.should be_attempt
      end
    end

    describe "#attempt!" do
      it "passes when times called more than times" do
        4.times {expectation.attempt}
      end

      it "passes when times called == times" do
        3.times {expectation.attempt}
      end

      it "passes when times called < times" do
        expectation.attempt
      end
    end

    describe "#terminal?" do
      it "returns false" do
        expectation.should_not be_terminal
      end
    end
  end

end
end