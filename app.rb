require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'ruby_llm'

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