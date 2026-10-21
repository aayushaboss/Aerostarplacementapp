/// Which resume-building experience the app uses.
///
/// [guided] is **Resume flow 1**: the 7-step quiz (`ResumeBuilderQuizScreen`).
/// [chat] is **Resume flow 2**: the chat-based Resume Helper
/// (`ResumeChatScreen`). Flipping [kResumeFlow] back to [guided] restores
/// flow 1 everywhere; flow 1's code is untouched either way, and git tag
/// `resume-flow-1` marks the last commit where it was the only flow.
enum ResumeFlow { guided, chat }

const kResumeFlow = ResumeFlow.chat;
