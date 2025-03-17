# RubyLLM Playground

A simple Sinatra application that serves as a playground for exploring [RubyLLM](https://rubyllm.com) features. Currently deployed on Railway.  

## Current Features

- Basic chat interface with session-based history
- Simple web UI for interaction
- Environment-based configuration
- Session-based conversation management

## Getting Started

1. Clone the repository
2. Set your OpenAI API key:
   ```bash
   export OPENAI_API_KEY=your_key_here
   ```
3. Install dependencies:
   ```bash
   npm install
   bundle install
   ```
4. Run the application:
   ```bash
   npm run build
   bundle exec ruby app.rb
   ```
5. Visit `http://localhost:8080` in your browser


### 1. Tool Integration Projects
- setup tools.
- try MCP integration
- try "CodeAgent" ala smolagent

### 2. Chat Enhancement Projects
- add streaming responses support
- implement chat history persistence using SQLite
- add conversation summarization feature

### 3. UI/UX Improvements
- custom commands? (\compact, \fetch etc)
- implement markdown rendering for responses
- add code syntax highlighting
- create a chat export feature
- add conversation branching!

### 4....
- add conversation analytics (token usage, response times)
- implement rate limiting and quota management

### 5. Integration stuff
- add background job processing
- implement WebSocket support for real-time updates
- add authentication system
- Implement chat room features

## Contributing

Feel free to:
1. Pick any project from the list above
2. Create a new branch
3. Implement the feature
4. Submit a pull request

## Resources

- [RubyLLM Documentation](https://rubyllm.com)
- [RubyLLM Chat Guide](https://rubyllm.com/guides/chat)
- [RubyLLM Tools Guide](https://rubyllm.com/guides/tools)

## License

MIT License 