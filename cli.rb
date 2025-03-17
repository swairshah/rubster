#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'tty-box'
  gem 'tty-screen'
  gem 'tty-cursor'
  gem 'tty-prompt'
  gem 'tty-markdown'
  gem 'tty-spinner'
  gem 'pastel'
  gem 'ruby_llm'
end

class CliChat
  THEMES = {
    user: {
      color: :cyan,
      prefix: "> "
    },
    assistant: {
      color: :blue,
      prefix: "< "
    },
    system: {
      color: :white,
      prefix: "# "
    }
  }

  def initialize
    @pastel = Pastel.new
    @prompt = TTY::Prompt.new
    @history = []
    @cursor = TTY::Cursor
    setup_llm
  end

  def setup_llm
    if ENV['OPENAI_API_KEY'].nil?
      puts @pastel.red("⚠️  OPENAI_API_KEY environment variable not set!")
      key = @prompt.mask("Please enter your OpenAI API key:")
      ENV['OPENAI_API_KEY'] = key
    end

    RubyLLM.configure do |config|
      config.openai_api_key = ENV["OPENAI_API_KEY"]
    end
    @chat_client = RubyLLM.chat
  end

  def display_message(role:, content:, timestamp: Time.now.strftime("%H:%M"))
    width = TTY::Screen.width
    theme = THEMES[role]
    
    if role == :assistant
      puts "\n#{theme[:prefix]} #{@pastel.send(theme[:color], 'Assistant')} (#{timestamp})"
      puts "#{content}\n"
      @history << { role: role, content: content, timestamp: timestamp }
      return
    end
    
    header = "#{theme[:prefix]} #{role.to_s.capitalize} (#{timestamp})"
    
    box = TTY::Box.frame(
      width: width - 4,
      padding: [0, 1],
      title: { top_left: header },
      style: {
        fg: theme[:color],
        border: {
          fg: theme[:color]
        }
      }
    ) do
      content
    end

    puts box
    @history << { role: role, content: content, timestamp: timestamp }
  end

  def get_input
    prefix = "#{THEMES[:user][:prefix]}"
    @prompt.ask("\n#{prefix}") do |q|
      q.modify :strip
      q.validate(/\S+/, 'Input cannot be empty')
    end
  end

  def clear_screen
    print @cursor.clear_screen
    print @cursor.move_to(0, 0)
  end

  def display_help
    help_text = <<~HELP
      Available Commands:
      /exit     - Exit the chat
      /clear    - Clear chat history
      /help     - Show this help message
      /save     - Save conversation to file
      /load     - Load conversation from file
    HELP

    display_message(
      role: :system,
      content: help_text
    )
  end

  def save_conversation(filename = "chat_history.json")
    File.write(filename, JSON.pretty_generate(@history))
    display_message(
      role: :system,
      content: "✅ Conversation saved to #{filename}"
    )
  end

  def load_conversation(filename = "chat_history.json")
    if File.exist?(filename)
      @history = JSON.parse(File.read(filename), symbolize_names: true)
      clear_screen
      @history.each do |msg|
        display_message(**msg)
      end
      display_message(
        role: :system,
        content: "✅ Conversation loaded from #{filename}"
      )
    else
      display_message(
        role: :system,
        content: "❌ No saved conversation found"
      )
    end
  end

  def display_welcome
    clear_screen
    welcome_text = <<~WELCOME
      Type '/help' to see available commands.
    WELCOME

    display_message(
      role: :system,
      content: welcome_text
    )
  end

  def handle_command(input)
    case input
    when '/exit'
      puts @pastel.yellow("\n 👋")
      exit
    when '/clear'
      @history.clear
      clear_screen
      display_welcome
    when '/help'
      display_help
    when '/save'
      save_conversation
    when '/load'
      load_conversation
    else
      return false
    end
    true
  end

  def start_chat
    display_welcome

    loop do
      input = get_input
      next if handle_command(input)

      # display_message(role: :user, content: input)
      
      # print "#{THEMES[:assistant][:prefix]}"  

      begin
        spinner = TTY::Spinner.new(":spinner", format: :dots)
        spinner.auto_spin
        response = @chat_client.ask(input)
        # print @cursor.clear_line         # Clear the spinner line
        spinner.stop
        # print @cursor.column(0)          # Move cursor to beginning of line
        display_message(role: :assistant, content: response.content)
      rescue => e
        spinner.stop
        print @cursor.clear_line         # Clear the spinner line
        print @cursor.column(0)          # Move cursor to beginning of line
        display_message(
          role: :system,
          content: "❌ Error: #{e.message}"
        )
      end
    end
  end
end

# Start the chat interface
CliChat.new.start_chat 