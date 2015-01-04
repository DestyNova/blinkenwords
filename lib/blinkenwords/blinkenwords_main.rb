# -*- coding: utf-8 -*-
# BlinkenWords GUI code
# © Oisín Mac Fhearaí <denpashogai/gmail> February 2010

begin
  require 'rubygems'
rescue LoadError
end

require 'wx'
require 'blinkenwords/blinkenwords_model'

class BlinkenWords < Wx::App
  def on_init
    # configure GUI
    @main_frame = Wx::Frame.new(nil, :title => "BlinkenWords", :size => Wx::Size.new(600, 300))
    main_panel = Wx::Panel.new(@main_frame)
    sizer = Wx::GridBagSizer.new(4, 4)
    sizer.add_growable_col(2)
    sizer.add_growable_row(6) # hack to make the readText cell grow
    main_panel.set_sizer(sizer)

    @main_frame.set_menu_bar create_menu_bar

    @reading_text = Wx::RichTextCtrl.new(main_panel, -1, :style => Wx::TE_READONLY)
    font = Wx::Font.new(14, Wx::FONTFAMILY_SWISS, Wx::FONTSTYLE_NORMAL, Wx::FONTWEIGHT_NORMAL)
    @text_style = Wx::RichTextAttr.new(Wx::RED)
    @text_style.set_alignment(Wx::TEXT_ALIGNMENT_CENTRE)
    @reading_text.set_default_style(@text_style)
    @reading_text.set_style(0..1000, @text_style)
    @reading_text.set_font(font)
    @reading_text.disable

    @reading_progress = Wx::Gauge.new(main_panel, -1, 100)
    @playButton = Wx::Button.new(main_panel, -1, 'Pl&ay')
    paste_new_button = Wx::Button.new(main_panel, -1, 'Paste &new')

    wpm_label = Wx::StaticText.new(main_panel, :label => 'WPM:')
    @wpm_choice = Wx::SpinCtrl.new(main_panel, :value => '270', :min => 60, :max => 1500, :initial => 270)
    words_per_group_label = Wx::StaticText.new(main_panel, :label => 'Words/block:')
    @words_per_group_choice = Wx::SpinCtrl.new(main_panel, :value => '3', :min => 1, :max => 10, :initial => 3)

    rewind_button = Wx::Button.new(main_panel, -1, '<')
    forward_button = Wx::Button.new(main_panel, -1, '>')

    about_button = Wx::Button.new(main_panel, -1, 'About')

    sizer.add(@playButton, Wx::GBPosition.new(0,0), Wx::GBSpan.new(1, 2), Wx::GROW)
    sizer.add(paste_new_button, Wx::GBPosition.new(1,0), Wx::GBSpan.new(1, 2), Wx::GROW)
    sizer.add(wpm_label, Wx::GBPosition.new(2,0), Wx::GBSpan.new(1, 1), Wx::ALIGN_CENTRE_VERTICAL|Wx::ALIGN_LEFT)
    sizer.add(@wpm_choice, Wx::GBPosition.new(2,1), Wx::GBSpan.new(1, 1), Wx::GROW)
    sizer.add(words_per_group_label, Wx::GBPosition.new(3,0), Wx::GBSpan.new(1, 1), Wx::ALIGN_CENTRE_VERTICAL|Wx::ALIGN_LEFT)
    sizer.add(@words_per_group_choice, Wx::GBPosition.new(3,1), Wx::GBSpan.new(1, 1), Wx::GROW)
    sizer.add(rewind_button, Wx::GBPosition.new(4,0), Wx::GBSpan.new(1, 1), Wx::ALIGN_LEFT)
    sizer.add(forward_button, Wx::GBPosition.new(4,1), Wx::GBSpan.new(1, 1), Wx::ALIGN_RIGHT)
    sizer.add(about_button, Wx::GBPosition.new(5,0), Wx::GBSpan.new(1, 2), Wx::GROW)

    sizer.add(@reading_progress, Wx::GBPosition.new(0,2), Wx::GBSpan.new(1, 1), Wx::GROW)
    sizer.add(@reading_text, Wx::GBPosition.new(1,2), Wx::GBSpan.new(6, 1), Wx::GROW)
    sizer.layout
    @main_frame.show
    #@main_frame.show

    paste_new_button.set_focus

    # model
    @playing = false
    @finished_playing = false
    @model = BlinkenwordsModel.new
    @wpm = @wpm_choice.get_value
    @words_per_group = @words_per_group_choice.get_value
    @next_words = ''

    # set up event handlers
    evt_button @playButton, :toggle_play
    evt_button paste_new_button, :paste_new
    evt_button rewind_button, :rewind
    evt_button forward_button, :fast_forward
    evt_button about_button, :about
    evt_spinctrl(@wpm_choice) { |event| update_speed(event.get_position - @wpm) }

    acc_table = Wx::AcceleratorTable[
      [ Wx::ACCEL_NORMAL, Wx::K_DOWN, @playButton.id],
      [ Wx::ACCEL_NORMAL, Wx::K_LEFT, rewind_button.id],
      [ Wx::ACCEL_NORMAL, Wx::K_RIGHT, forward_button.id],
      [ Wx::ACCEL_NORMAL, Wx::K_UP, paste_new_button.id]
    ]
    @main_frame.accelerator_table = acc_table

    # work around stupid thread bug (even in ruby 1.9? aren't we using OS threads?)
    timer = Wx::Timer.new(self, Wx::ID_ANY)
    evt_timer(timer.id) do
      # while we're at it, do GUI update here rather than in the other thread...
      if !@next_words.empty?
        @reading_progress.set_value(@model.position)
        @reading_text.set_value(@next_words)
        @reading_text.set_style(0..1000, @text_style)
        @next_words = ''
      end
      if @finished_playing
        @finished_playing = false
        stop_playing
      end
      Thread.pass
    end
    timer.start(10)

    start_update_thread
  end

  def update_speed wpm_difference
    if wpm_difference.abs == 1
      wpm_difference = 5*wpm_difference
    else
      wpm_difference = wpm_difference / 5 * 5 # what function is this?
    end

    @wpm += wpm_difference
    @wpm_choice.set_value(@wpm)
  end

  def create_menu_bar
    menubar = Wx::MenuBar.new
    control_menu = Wx::Menu.new
    help_menu = Wx::Menu.new

    play_item = control_menu.append("Toggle playing\tDOWN")
    evt_menu play_item, :toggle_play

    new_item = control_menu.append("Paste new item from clipboard\tUP")
    evt_menu new_item, :paste_new

    rewind_item = control_menu.append("Rewind\tLEFT")
    evt_menu rewind_item, :rewind

    forward_item = control_menu.append("Fast forward\tRIGHT")
    evt_menu forward_item, :fast_forward

    speed_up_item = control_menu.append("Speed +5 wpm\t]")
    evt_menu(speed_up_item) { update_speed 5 }

    speed_down_item = control_menu.append("Speed -5 wpm\t[")
    evt_menu(speed_down_item) { update_speed -5 }

    menubar.append(control_menu, 'Control')
    menubar
  end

  def about
    about_box = Wx::AboutDialogInfo.new
    about_box.set_version '0.0.4'
    about_box.set_name 'Blinkenwords'
    about_box.add_developer "Oisín Mac Fhearaí"
    about_box.set_web_site 'https://github.com/DestyNova/blinkenwords'
    Wx::about_box(about_box)
  end

  def rewind
    stop_playing
    @model.rewind(@words_per_group*2)
    fast_forward
  end

  def fast_forward
    stop_playing
    next_words = @model.get_next_words(@words_per_group)
    @reading_progress.set_value(@model.position)
    @next_words = next_words
  end

  def stop_playing
    if @playing
      toggle_play
    end
  end

  def toggle_play
    # update values
    @wpm = @wpm_choice.get_value
    @words_per_group = @words_per_group_choice.get_value

    if @playing
      @playButton.set_label 'Pl&ay'
    else
      @playButton.set_label 'P&ause'
    end

    @playing = !@playing
  end

  def paste_new
    toggle_play if @playing

    new_text = Wx::Clipboard.open do |clip|
      if clip.supported?(Wx::DF_TEXT)
        txt = Wx::TextDataObject.new
        clip.get_data(txt)
        txt.text
      end
    end
    @model.set_text(new_text)

    word_count = @model.length
    @reading_progress.set_range(word_count)
    @reading_progress.set_value(0)
    @reading_text.set_value("[words: #{word_count} expected time: #{(Float(word_count)/@wpm*60 + word_count/25.0).round} seconds]")
  end

  def start_update_thread
    Thread.new do
      loop do
        begin
          #                  puts "1: #{Time.new}"
          #                  puts "1b: #{Time.new}"
          #                  puts "1c: #{Time.new}"
          #                  puts "1d: #{Time.new}"
          if @playing
            next_words = @model.get_next_words(@words_per_group)
            if !next_words.empty?
              @next_words = next_words
              delay_time = (60.0/@wpm)*@words_per_group
              delay_time += 0.5 if next_words.length > @words_per_group*7 or next_words.index(/\.|!|\?|:|;/)
              sleep delay_time
            else
              @finished_playing = true  # don't mess with GUI from here! let timer task do that
            end
          else
            sleep 0.5
          end
        rescue
          puts $! # print exception manually, otherwise it'll get lost by the thread
        end
      end
    end
  end
end

BlinkenWords.new.main_loop
