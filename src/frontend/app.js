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
let loading = true;
let generation = 0;

async function showDeploymentInfo() {
  try {
    const response = await fetch("./deployment.json", { cache: "no-store" });
    if (!response.ok) throw new Error(`Metadata request failed: ${response.status}`);
    const metadata = await response.json();
    if (typeof metadata.image === "string" && metadata.image) {
      document.querySelector("#deployment-image").textContent = metadata.image;
    }
    if (typeof metadata.deployedAt === "string" && metadata.deployedAt.endsWith("Z")) {
      const timestamp = new Date(metadata.deployedAt);
      if (!Number.isNaN(timestamp.getTime())) {
        const element = document.querySelector("#deployment-time");
        element.dateTime = metadata.deployedAt;
        element.textContent = `${timestamp.toISOString().replace("T", " ").replace(".000Z", " UTC").replace("Z", " UTC")}`;
      }
    }
  } catch (error) {
    console.error("Deployment metadata is unavailable.", error);
  }
}

function updateSendState() {
  sendButton.disabled = loading || pendingReply !== null || input.value.trim().length === 0;
  suggestions.forEach((button) => { button.disabled = loading || pendingReply !== null; });
  resetButton.disabled = loading;
}

function appendFormattedText(element, text) {
  const boldPattern = /\*\*([^\n]+?)\*\*/g;
  let offset = 0;
  for (const match of text.matchAll(boldPattern)) {
    element.append(document.createTextNode(text.slice(offset, match.index)));
    const strong = document.createElement("strong");
    strong.textContent = match[1];
    element.append(strong);
    offset = match.index + match[0].length;
  }
  element.append(document.createTextNode(text.slice(offset)));
}

function renderAssistantMessage(body, text) {
  const lines = text.replace(/\r\n?/g, "\n").split("\n");
  let paragraph = [];
  let list = null;

  function flushParagraph() {
    if (paragraph.length === 0) return;
    const element = document.createElement("p");
    appendFormattedText(element, paragraph.join("\n"));
    body.append(element);
    paragraph = [];
  }

  for (const line of lines) {
    if (!line.trim()) {
      flushParagraph();
      list = null;
      continue;
    }

    const item = line.match(/^\s{0,3}(?:[-+*]|\d+[.)])\s+(.+)$/);
    if (item) {
      flushParagraph();
      const number = line.match(/^\s{0,3}(\d+)[.)]\s+/);
      const tag = number ? "ol" : "ul";
      if (!list || list.localName !== tag) {
        list = document.createElement(tag);
        if (number) list.setAttribute("start", number[1]);
        body.append(list);
      }
      const element = document.createElement("li");
      appendFormattedText(element, item[1]);
      list.append(element);
      continue;
    }

    list = null;
    paragraph.push(line);
  }
  flushParagraph();
}

function appendMessage(role, text, model = null) {
  const article = document.createElement("article");
  article.className = `message message-${role}`;
  const label = document.createElement("h2");
  label.className = "message-label";
  label.textContent = role === "user" ? "You" : "Ski School";
  const body = document.createElement(role === "assistant" ? "div" : "p");
  body.className = "message-body";
  if (role === "assistant") {
    renderAssistantMessage(body, text);
  } else {
    body.textContent = text;
  }
  article.append(label, body);
  if (role === "assistant") {
    const attribution = document.createElement("p");
    attribution.className = "message-model";
    attribution.textContent = typeof model === "string" && model.trim()
      ? `Model: ${model.trim()}`
      : "Model unavailable";
    article.append(attribution);
  }
  messages.append(article);
}

async function api(path, options = {}) {
  const result = await fetch(path, { ...options, cache: "no-store" });
  const data = await result.json();
  if (!result.ok) throw new Error(typeof data.error === "string" ? data.error : "The service is unavailable.");
  return data;
}

async function loadHistory() {
  replyStatus.textContent = "Loading your chat...";
  try {
    const data = await api("/api/conversation");
    if (!Array.isArray(data.messages)) throw new Error("Conversation history is unavailable.");
    for (const message of data.messages) {
      if (!["user", "assistant"].includes(message.role) || typeof message.text !== "string") {
        throw new Error("Conversation history is unavailable.");
      }
      appendMessage(message.role, message.text, message.model);
    }
    welcome.hidden = data.messages.length > 0;
    conversation.hidden = data.messages.length === 0;
    replyStatus.textContent = "";
    loading = false;
  } catch (error) {
    messages.replaceChildren();
    replyStatus.textContent = `${error.message} Reload the page or start a new chat.`;
    resetButton.disabled = false;
    return;
  }
  updateSendState();
}

async function submitMessage(text) {
  const message = text.trim();
  if (!message || loading || pendingReply !== null) return;
  const currentGeneration = generation;
  let finishReply;
  pendingReply = new Promise((resolve) => { finishReply = resolve; });
  welcome.hidden = true;
  conversation.hidden = false;
  appendMessage("user", message);
  input.value = "";
  replyStatus.textContent = "Ski School is thinking...";
  updateSendState();
  form.scrollIntoView({ block: "nearest" });
  try {
    const data = await api("/api/messages", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message }),
    });
    if (typeof data.reply !== "string" || !data.reply) throw new Error("The assistant returned an empty reply.");
    if (currentGeneration !== generation) return;
    appendMessage("assistant", data.reply, data.model);
    replyStatus.textContent = "";
  } catch (error) {
    if (currentGeneration !== generation) return;
    replyStatus.textContent = `${error.message} The message may have been received; reload to check.`;
  } finally {
    finishReply();
    if (currentGeneration === generation) {
      pendingReply = null;
      updateSendState();
    }
  }
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
resetButton.addEventListener("click", async () => {
  const historyWasUnavailable = loading;
  const previousReply = pendingReply;
  generation += 1;
  loading = true;
  updateSendState();
  replyStatus.textContent = previousReply
    ? "Waiting for the current reply before deleting your chat..."
    : "Deleting your previous chat...";
  try {
    await previousReply;
    pendingReply = null;
    replyStatus.textContent = "Deleting your previous chat...";
    await api("/api/reset", { method: "POST" });
    messages.replaceChildren();
    welcome.hidden = false;
    conversation.hidden = true;
    input.value = "";
    replyStatus.textContent = "New chat started.";
    input.focus({ preventScroll: true });
    welcome.scrollIntoView({ block: "start" });
    loading = false;
  } catch (error) {
    replyStatus.textContent = error.message;
    loading = historyWasUnavailable;
  }
  updateSendState();
  if (historyWasUnavailable && loading) resetButton.disabled = false;
});

showDeploymentInfo();
updateSendState();
loadHistory();
