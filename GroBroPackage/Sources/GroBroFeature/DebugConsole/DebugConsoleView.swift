import SwiftUI
import GroBroDomain

@available(iOS 17.0, *)
public struct DebugConsoleView: View {
    @StateObject private var viewModel: DebugConsoleViewModel
    @FocusState private var isInputFocused: Bool

    public init(viewModel: DebugConsoleViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Mode indicator
            HStack {
                Image(systemName: viewModel.mode == .online ? "wifi" : "wifi.slash")
                    .foregroundColor(viewModel.mode == .online ? .green : .orange)

                Text(viewModel.mode == .online ? "Online Mode" : "Limited Mode (Offline)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))

            Divider()

            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.messages.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }

                        if viewModel.isProcessing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input area
            HStack(spacing: 12) {
                TextField("Ask about your plant...", text: $viewModel.currentInput, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .disabled(viewModel.isProcessing)

                Button {
                    Task {
                        await viewModel.sendMessage()
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.canSend ? .blue : .gray)
                }
                .disabled(!viewModel.canSend)
            }
            .padding()
            .background(.background)
        }
        .navigationTitle("Debug Console")
        .inlineNavigationTitle()
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundColor(.green.opacity(0.5))

            Text("Ask About Your Plant")
                .font(.title3)
                .fontWeight(.semibold)

            Text("I can help with questions about watering, nutrients, pests, light, and general plant health.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 8) {
                Text("Example questions:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach([
                    "Why are the leaves turning yellow?",
                    "How often should I water?",
                    "Is this light stress?"
                ], id: \.self) { example in
                    Button {
                        viewModel.currentInput = example
                    } label: {
                        Text("• \(example)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(.vertical, 40)
    }
}

@available(iOS 17.0, *)
struct MessageBubble: View {
    let message: DebugMessage

    var body: some View {
        HStack {
            if message.isUserMessage {
                Spacer()
            }

            VStack(alignment: message.isUserMessage ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(message.isUserMessage ? Color.blue : Color.gray.opacity(0.1))
                    .foregroundColor(message.isUserMessage ? .white : .primary)
                    .cornerRadius(16)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 280, alignment: message.isUserMessage ? .trailing : .leading)

            if !message.isUserMessage {
                Spacer()
            }
        }
    }
}
