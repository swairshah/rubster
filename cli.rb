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

require_relative 'llm'

class ChatApp
  def initialize
    @history = []
  end

  def add_to_history(role:, content:, timestamp: Time.now.strftime("%H:%M"))
    @history << { role: role, content: content, timestamp: timestamp }
  end

  def history
    @history.dup
  end

  def clear_history
    @history.clear
  end

  def ask(input)
    LLMClient.ask(input)
  end

  def save_conversation(filename = "chat_history.json")
    require 'json'
    File.write(filename, JSON.pretty_generate(@history))
    true
  end

  def load_conversation(filename = "chat_history.json")
    require 'json'
    if File.exist?(filename)
      @history = JSON.parse(File.read(filename), symbolize_names: true)
      true
    else
      false
    end
  end
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
    @cursor = TTY::Cursor
    @app = ChatApp.new
    setup_llm
  end

  def setup_llm
    if ENV['OPENAI_API_KEY'].nil?
      puts @pastel.red("⚠️  OPENAI_API_KEY environment variable not set!")
      key = @prompt.mask("Please enter your OpenAI API key:")
      ENV['OPENAI_API_KEY'] = key
    end
    
    LLMClient.setup
  end

  def display_message(role:, content:, timestamp: Time.now.strftime("%H:%M"))
    width = TTY::Screen.width
    theme = THEMES[role]
    
    if role == :assistant
      puts "\n#{theme[:prefix]} #{@pastel.send(theme[:color], 'Assistant')} (#{timestamp})"
      puts "#{content}\n"
      @app.add_to_history(role: role, content: content, timestamp: timestamp)
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
    @app.add_to_history(role: role, content: content, timestamp: timestamp)
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
    if @app.save_conversation(filename)
      display_message(
        role: :system,
        content: "✅ Conversation saved to #{filename}"
      )
    end
  end

  def load_conversation(filename = "chat_history.json")
    if @app.load_conversation(filename)
      clear_screen
      @app.history.each do |msg|
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
      @app.clear_history
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

      begin
        spinner = TTY::Spinner.new(":spinner", format: :dots)
        spinner.auto_spin
        response = @app.ask(input)
        spinner.stop
        display_message(role: :assistant, content: response.content)
      rescue => e
        spinner.stop
        display_message(
          role: :system,
          content: "❌ Error: #{e.message}"
        )
      end
    end
  end
end

if __FILE__ == $0
  CliChat.new.start_chat
end 