require 'ruby_llm'

class LLMClient
  class Error < StandardError; end

  def self.setup(api_key = nil)
    api_key ||= ENV['OPENAI_API_KEY']
    raise Error, "OpenAI API key not provided" unless api_key

    RubyLLM.configure do |config|
      config.openai_api_key = api_key
    end
  end

  def self.chat_client
    @chat_client ||= begin
      setup unless @configured
      RubyLLM.chat
    end
  end

  def self.ask(input)
    chat_client.ask(input)
  end

  def self.configured?
    !@chat_client.nil?
  end
end 