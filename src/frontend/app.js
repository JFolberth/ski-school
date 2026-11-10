const form = document.querySelector("#chat-form");
const input = document.querySelector("#message");
const sendButton = document.querySelector("#send");
const resetButton = document.querySelector("#reset");
const welcome = document.querySelector("#welcome");
const conversation = document.querySelector("#conversation");
const messages = document.querySelector("#messages");
const replyStatus = document.querySelector("#reply-status");
const suggestions = document.querySelectorAll("[data-prompt]");

let pendingReply = null;

const demoReplies = [
  {
    matches: /\b(snow|conditions?|weather|forecast|grooming|lifts?|trails?)\b/i,
    text: "Let's separate the weather from what's happening on the hill.\n\nWeather observations and forecasts describe the atmosphere. Resort reports describe snow surfaces, grooming, and open lifts and trails. A snowy forecast isn't confirmation of fresh snow on a run.\n\nIn a connected experience, each report would need its source, observation time, and freshness. Live data is unavailable in this demo, so I can't tell you what's open or how the snow is right now.",
  },
  {
    matches: /\b(locations?|near|nearby|close|closer|drive|driving|region|town|city)\b/i,
    text: "Let's start with where in Michigan you'd like to ski.\n\nA useful search would consider your starting town, how far you'd like to travel, and the kind of terrain you're looking for. Try asking about a region or adding those preferences to your next message.\n\nThis is a scripted preview, not a location search. I haven't checked a map, travel times, or resort availability.",
  },
  {
    matches: /\b(michigan|resorts?|ski|skiing|hills?|beginner|terrain)\b/i,
    text: "Let's find your kind of Michigan ski day.\n\nA resort comparison could start with your preferred region, experience level, and the terrain you enjoy. Then you'd check resort-reported trail and lift status separately from the weather forecast.\n\nThis demo doesn't have a resort directory or live reports connected. I can't recommend a specific resort based on current conditions, but you can try the snow or location prompts to explore the chat experience.",
  },
];

function updateSendState() {
  sendButton.disabled = pendingReply !== null || input.value.trim().length === 0;
}

function appendMessage(role, text) {
  const article = document.createElement("article");
  article.className = `message message-${role}`;

  const label = document.createElement("h2");
  label.className = "message-label";
  label.textContent = role === "user" ? "You" : "Ski School / Scripted demo";

  const body = document.createElement("p");
  body.className = "message-body";
  body.textContent = text;

  article.append(label, body);
  messages.append(article);
}

function submitMessage(text) {
  const message = text.trim();
  if (!message || pendingReply !== null) return;

  welcome.hidden = true;
  conversation.hidden = false;
  appendMessage("user", message);
  input.value = "";
  replyStatus.textContent = "Ski School is typing a scripted demo reply...";
  suggestions.forEach((button) => { button.disabled = true; });

  pendingReply = window.setTimeout(() => {
    const nearBottom = window.scrollY + window.innerHeight >= document.documentElement.scrollHeight - 120;
    const reply = demoReplies.find((candidate) => candidate.matches.test(message));
    appendMessage("assistant", reply?.text ?? "This preview uses a few scripted replies about Michigan skiing, not an AI model. I can't answer that request here.\n\nTry asking about Michigan resorts, snow conditions, or skiing locations. No live data is connected.");
    pendingReply = null;
    replyStatus.textContent = "";
    suggestions.forEach((button) => { button.disabled = false; });
    updateSendState();
    if (nearBottom) form.scrollIntoView({ block: "nearest" });
  }, 900);

  updateSendState();
  input.focus({ preventScroll: true });
  form.scrollIntoView({ block: "nearest" });
}

form.addEventListener("submit", (event) => {
  event.preventDefault();
  submitMessage(input.value);
});

input.addEventListener("input", updateSendState);
input.addEventListener("keydown", (event) => {
  if (event.key === "Enter" && !event.shiftKey && !event.isComposing) {
    event.preventDefault();
    if (!sendButton.disabled) form.requestSubmit();
  }
});

suggestions.forEach((button) => {
  button.addEventListener("click", () => submitMessage(button.dataset.prompt));
});

resetButton.addEventListener("click", () => {
  window.clearTimeout(pendingReply);
  pendingReply = null;
  messages.replaceChildren();
  welcome.hidden = false;
  conversation.hidden = true;
  input.value = "";
  replyStatus.textContent = "New chat started.";
  suggestions.forEach((button) => { button.disabled = false; });
  updateSendState();
  input.focus({ preventScroll: true });
  welcome.scrollIntoView({ block: "start" });
});
