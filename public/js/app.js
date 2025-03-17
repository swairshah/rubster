"use strict";
Alpine.data('chat', function () {
    return {
        messages: window.initialMessages || [],
        userInput: '',
        isLoading: false,
        $nextTick: Alpine.$nextTick,
        init() {
            this.scrollToBottom();
            this.$nextTick(() => {
                var _a;
                (_a = document.querySelector('input[type="text"]')) === null || _a === void 0 ? void 0 : _a.focus();
            });
        },
        sendMessage() {
            if (!this.userInput.trim())
                return;
            const userMessage = {
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
                    var _a;
                    (_a = document.querySelector('input[type="text"]')) === null || _a === void 0 ? void 0 : _a.focus();
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
