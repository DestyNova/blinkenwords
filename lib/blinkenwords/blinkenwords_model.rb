# -*- coding: utf-8 -*-
# model for BlinkenWords
# © Oisín Mac Fhearaí <denpashogai/gmail> February 2010

class BlinkenwordsModel
  attr_reader :position, :length

  def initialize
    @text = []
    @position = 0
    @length = 0
  end

  def set_text text
    @text = text.split(/[ \n]+/)
    @position = 0
    @length = @text.length
  end

  def get_next_words amount
    next_chunk = @text[@position..@position+amount-1]
    if next_chunk
      result = next_chunk.join "\n"
      @position = [@length, @position + amount].min
      result
    else
      nil
    end
  end

  def rewind amount
    @position = [0, @position - amount].max
  end
end
