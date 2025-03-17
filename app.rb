require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'ruby_llm'
require_relative 'llm'

RubyLLM.configure do |config|
  config.openai_api_key = ENV["OPENAI_API_KEY"]
end

enable :sessions

set :port, ENV['PORT'] || 8080
set :bind, '0.0.0.0'
set :public_folder, File.dirname(__FILE__) + '/public'

configure :development do
  set :environment, :development
  # don't need strict host checking in dev
  set :protection, :except => [:http_origin]
end

configure :production do
  set :environment, :production
  set :hosts, [
    /.*\.railway\.app$/,
    "127.0.0.1",
    "localhost"
  ]
end

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

  def ask(input)
    response = LLMClient.ask(input)
    add_to_history(role: :user, content: input)
    add_to_history(role: :assistant, content: response.content)
    response
  end
end

get '/' do
  session[:conversation] ||= []
  erb :index, locals: { conversation: session[:conversation].to_json }
end

post '/message' do
  content_type :json
  request_payload = JSON.parse(request.body.read)
  message = request_payload['message']
  
  session[:chat_client] ||= RubyLLM.chat
  
  response = { 
    response: ask_llm(message.to_s),
    timestamp: Time.now.strftime("%H:%M")
  }
  
  session[:conversation] << response
  response.to_json
end

post '/clear' do
  session[:conversation] = []
  session[:chat_client] = RubyLLM.chat  
  content_type :json
  { success: true }.to_json
end

private

def ask_llm(prompt)
  response = session[:chat_client].ask prompt
  response.content
end