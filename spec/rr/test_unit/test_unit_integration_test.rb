dir = File.dirname(__FILE__)
require "#{dir}/test_helper"

class TestUnitIntegrationTest < Test::Unit::TestCase
  def setup
    super
    @subject = Object.new
  end

  def teardown
    super
  end

  def test_using_a_mock
    mock(@subject).foobar(1, 2) {:baz}
    assert_equal :baz, @subject.foobar(1, 2)
  end
  
  def test_using_a_stub
    stub(@subject).foobar {:baz}
    assert_equal :baz, @subject.foobar("any", "thing")
  end

  def test_using_a_mock_proxy
    def @subject.foobar
      :baz
    end

    mock.proxy(@subject).foobar
    assert_equal :baz, @subject.foobar
  end

  def test_using_a_stub_proxy
    def @subject.foobar
      :baz
    end

    stub.proxy(@subject).foobar
    assert_equal :baz, @subject.foobar
  end

  def test_times_called_verification
    mock(@subject).foobar(1, 2) {:baz}
    assert_raise RR::Errors::TimesCalledError do
      teardown
    end
  end
end
