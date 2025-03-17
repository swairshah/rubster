// src/app.ts
interface Message {
  id: number;
  role: 'user' | 'assistant';
  content: string;
  timestamp: string;
}

interface ChatState {
  messages: Message[];
  userInput: string;
  isLoading: boolean;
  
  init(): void;
  sendMessage(): void;
  clearChat(): void;
  scrollToBottom(): void;
}

declare const Alpine: any;

// Add this interface to properly type Alpine's properties
interface AlpineInstance extends ChatState {
  $nextTick: (callback: () => void) => void;
}

Alpine.data('chat', function(): AlpineInstance {
  return {
    messages: (window as any).initialMessages || [],
    userInput: '',
    isLoading: false,
    $nextTick: Alpine.$nextTick,
    
    init() {
      this.scrollToBottom();
      this.$nextTick(() => {
        (document.querySelector('input[type="text"]') as HTMLInputElement)?.focus();
      });
    },
    
    sendMessage() {
      if (!this.userInput.trim()) return;
      
      const userMessage: Message = {
        id: this.messages.length + 1,
        role: 'user',
        content: this.userInput,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      };
      
      this.messages.push(userMessage);
      this.isLoading = true;
      
      const input = this.userInput;
      this.userInput = '';
      
      fetch('/message', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: input })
      })
      .then(response => response.json())
      .then(data => {
        this.messages.push({
          id: this.messages.length + 1,
          role: 'assistant',
          content: data.response || data.content,
          timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        });
        
        this.isLoading = false;
        this.$nextTick(() => {
          (document.querySelector('input[type="text"]') as HTMLInputElement)?.focus();
        });
        this.scrollToBottom();
      })
      .catch(error => {
        console.error('Error:', error);
        this.isLoading = false;
      });
    },
    
    clearChat() {
      if (confirm('Clear conversation history?')) {
        fetch('/clear', { method: 'POST' })
          .then(() => {
            this.messages = [];
          });
      }
    },
    
    scrollToBottom() {
      setTimeout(() => {
        const container = document.getElementById('messages-container');
        if (container) {
          container.scrollTop = container.scrollHeight;
        }
      }, 50);
    }
  };
});