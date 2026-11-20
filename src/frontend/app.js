const form = document.querySelector("#chat-form");
const input = document.querySelector("#message");
const sendButton = document.querySelector("#send");
const resetButton = document.querySelector("#reset");
const welcome = document.querySelector("#welcome");
const conversation = document.querySelector("#conversation");
const messages = document.querySelector("#messages");
const replyStatus = document.querySelector("#reply-status");
const suggestions = document.querySelectorAll("[data-prompt]");

const MAX_EXCHANGES = 5;
const MAX_REQUEST_BYTES = 24 * 1024;
const encoder = new TextEncoder();
const history = [];
let pendingReply = null;

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
  sendButton.disabled = pendingReply !== null || input.value.trim().length === 0;
  suggestions.forEach((button) => { button.disabled = pendingReply !== null; });
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

function messageBody(message) {
  const exchanges = history.slice();
  while (true) {
    const body = JSON.stringify({ message, history: exchanges });
    if (encoder.encode(body).byteLength <= MAX_REQUEST_BYTES) return body;
    if (exchanges.length === 0) throw new Error("The chat request is too large.");
    exchanges.shift();
  }
}

async function submitMessage(text) {
  const message = text.trim();
  if (!message || pendingReply !== null) return;
  const currentReply = new AbortController();
  pendingReply = currentReply;
  welcome.hidden = true;
  conversation.hidden = false;
  appendMessage("user", message);
  input.value = "";
  replyStatus.textContent = "Ski School is thinking...";
  updateSendState();
  form.scrollIntoView({ block: "nearest" });
  try {
    const result = await fetch("/api/messages", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: messageBody(message),
      cache: "no-store",
      credentials: "omit",
      signal: currentReply.signal,
    });
    const data = result.headers.get("content-type")?.startsWith("application/json")
      ? await result.json() : null;
    if (!result.ok) throw new Error(typeof data?.error === "string" ? data.error : "The service is unavailable.");
    if (typeof data?.reply !== "string" || !data.reply.trim()) throw new Error("The assistant returned an empty reply.");
    if (pendingReply !== currentReply) return;
    history.push({ user: message, assistant: data.reply });
    if (history.length > MAX_EXCHANGES) history.shift();
    appendMessage("assistant", data.reply, data.model);
    replyStatus.textContent = "";
  } catch (error) {
    if (pendingReply !== currentReply) return;
    if (!input.value.trim()) input.value = message;
    replyStatus.textContent = `${error.message} You can send the message again.`;
  } finally {
    if (pendingReply === currentReply) {
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
resetButton.addEventListener("click", () => {
  pendingReply?.abort();
  pendingReply = null;
  history.length = 0;
  messages.replaceChildren();
  welcome.hidden = false;
  conversation.hidden = true;
  input.value = "";
  replyStatus.textContent = "New chat started.";
  input.focus({ preventScroll: true });
  welcome.scrollIntoView({ block: "start" });
  updateSendState();
});

showDeploymentInfo();
updateSendState();
