require File.dirname(__FILE__) + '/test_helper.rb'

require "test/unit"
require "blinkenwords/blinkenwords_model"

class BlinkenwordsModelTest < Test::Unit::TestCase
  def test_can_instantiate
    model = BlinkenwordsModel.new
    assert_not_nil model
  end

  def test_get_next_simple
    model = BlinkenwordsModel.new
    model.set_text "Eins zwei polizei das ist gut das ist los!"
    assert_equal("Eins\nzwei\npolizei", model.get_next_words(3))
  end

  def test_get_next_with_extra_whitespace
    model = BlinkenwordsModel.new
    model.set_text "Eins zwei\n polizei das ist gut das ist los!"
    assert_equal("Eins\nzwei\npolizei", model.get_next_words(3))
  end

  def test_get_next_with_repeated_whitespace
    model = BlinkenwordsModel.new
    model.set_text "Eins  \n  zwei\n polizei das ist gut das ist los!"
    assert_equal("Eins\nzwei\npolizei", model.get_next_words(3))
  end

  def test_get_next_multiple
    model = BlinkenwordsModel.new
    model.set_text "Eins zwei polizei das ist gut das ist los!"
    model.get_next_words(3)
    assert_equal("das\nist\ngut", model.get_next_words(3))
    assert_equal("das\nist", model.get_next_words(2))
    assert_equal("los!", model.get_next_words(3))
  end

  def test_rewind
    model = BlinkenwordsModel.new
    model.set_text "Eins zwei polizei das ist gut das ist los!"
    assert_equal("Eins\nzwei\npolizei", model.get_next_words(3))
    model.rewind(3)
    assert_equal("Eins\nzwei\npolizei", model.get_next_words(3))
    model.rewind(2)
    assert_equal("zwei\npolizei\ndas", model.get_next_words(3))
    model.rewind(30)
    assert_equal("Eins\nzwei\npolizei", model.get_next_words(3))
  end

  def test_set_text_resets
    model = BlinkenwordsModel.new
    model.set_text "Eins zwei polizei das ist gut das ist los!"
    assert_equal("Eins\nzwei\npolizei", model.get_next_words(3))
    assert_equal("das\nist\ngut", model.get_next_words(3))
    model.set_text "Eins zwei polizei das ist gut das ist los!"
    assert_equal("Eins\nzwei\npolizei", model.get_next_words(3))
  end

  def test_handles_no_input
    model = BlinkenwordsModel.new
    model.get_next_words(3)
  end

  def test_hanging_input
    text = "Test-unit gem not found, falling back to default test-unit"
    model = BlinkenwordsModel.new
    model.set_text text
    puts "1: #{model.get_next_words(3)}"
    puts "2: #{model.get_next_words(3)}"
    puts "3: #{model.get_next_words(3)}"
    puts "4: #{model.get_next_words(3)}"
    puts "5: #{model.get_next_words(3)}"  # this was causing an error by calling nil.join
  end

  def test_get_length
    model = BlinkenwordsModel.new
    model.set_text "Eins zwei polizei das ist gut das ist los!"
    assert_equal(9, model.length)
  end

  def test_get_position
    model = BlinkenwordsModel.new
    model.set_text "Eins zwei polizei"
    assert_equal(0, model.position)
    model.get_next_words(2)
    assert_equal(2, model.position)
    model.get_next_words(2)
    assert_equal(3, model.position)
  end

  def test_wpm_modulo
    assert_equal(200, 204/5*5)
  end
end
