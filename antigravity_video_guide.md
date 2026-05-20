# 📹 60-Second Antigravity Usage Video Recording Guide

This guide helps you record a high-impact **60-second screen recording** of your IDE showing exactly how **Google Antigravity / Agentic Code** was used to build, test, and harden the **Sitara** app.

---

## 🎬 The 60-Second Visual Timeline

| Time | Screen View (Visual) | Action (What to click/do) | Key Narration / Concept |
| :--- | :--- | :--- | :--- |
| **0:00 - 0:15** | **IDE Split Pane** (Left: `GEMINI.md` / Right: Terminal) | Highlight the active Antigravity session / Maestro orchestrator rules | *"We used Google Antigravity to co-pilot the entire life cycle of Sitara—running structured validation loops."* |
| **0:15 - 0:30** | **ASCII Architecture Map** (`Project_Architecture_Blueprint.md`) | Scroll down to the multi-agent ADK diagram | *"Our agent orchestrated the generation of 3 ADK LlmAgents, defining strict schemas for our Therapy Director swarm."* |
| **0:30 - 0:45** | **Terminal Command Run** | Run the custom Python verification test in terminal | *"We ran local verification loops directly in the IDE to validate state transitions and prevent hallucinations."* |
| **0:45 - 1:00** | **Live Trace Widget Dart Code** (`agent_trace_widget.dart` [Lines 105-158]) | Highlight the Animated Flow Diagram & Judge Sandbox code | *"Antigravity helped us build the real-time clinical telemetry widgets for absolute therapist transparency."* |

---

## 💻 Step-by-Step Recording Setup

### Step 1: Open these 3 files in VS Code (Tabs)
1. **[GEMINI.md](file:///d:/my-dev-knowledge-base/sitara/GEMINI.md)**
   - *Why?* Shows your primary Maestro-governed developer orchestration rules and GCP environment setups.
2. **[Project_Architecture_Blueprint.md](file:///d:/my-dev-knowledge-base/sitara/Project_Architecture_Blueprint.md)**
   - *Why?* Displays the beautiful 3-agent swarm system diagram.
3. **[agent_trace_widget.dart](file:///d:/my-dev-knowledge-base/sitara/sitara_app/lib/widgets/agent_trace_widget.dart)**
   - *Why?* Show **Lines 105 to 158** which contain the `_AgentFlowDiagram` and the complete `JUDGE SANDBOX: TRIGGER ORCHESTRATION` button bindings (Simulate Wins, Simulate Fails, Story Quest, Eval Now).

### Step 2: Open Terminal inside VS Code
Make sure your terminal is navigated to the project root:
```powershell
cd d:\my-dev-knowledge-base\sitara
```

### Step 3: Run this live test command during the video!
To show the judges that your agentically verified systems work instantly, run this integration test:
```powershell
adk_backend\venv\Scripts\python.exe adk_backend\verify_backend_local.py
```
*(This command will print a beautiful output confirming that your FastAPI endpoints, ADK agents, and fallbacks are 100% active and healthy!)*

---

## 🎙️ Verbal Script (Read this while recording)

> [!TIP]
> Keep your voice confident, enthusiastic, and direct.

*"Here is how we used Google Antigravity to build and verify Sitara. 
We configured our agent via a customized development protocol inside GEMINI.md. 
The agent designed the entire Multi-Agent ADK Architecture, generating three specialized LLM agents: the Therapy Director, the Story Weaver, and the Progress Guardian. 

To ensure clinical safety, we had our agent run continuous verification loops. When we run our local verification test, you can see all local FastAPI integrations, ADK pipelines, and the local FixedRuleEngine heuristic fallback system validate successfully in real-time. 

Finally, the agent designed and implemented our live Flutter developer console to translate complex agent trace logs directly onto the mobile client. With Antigravity, we built a fully autonomous, production-ready AAC game in under a week."*

---

## 🎥 Recording Settings Checklist
* **Resolution**: 1080p or 720p (720p is better to keep the file under **10MB**)
* **Tool**: Xbox Game Bar (`Win + G`) or OBS Studio
* **Format**: `.mp4`
* **Size Limit**: **10 MB maximum** (highly compressed)
* **Compression command** (if size is too big):
  ```bash
  ffmpeg -i input.mp4 -vf scale=1280:720 -b:v 800k -an output.mp4
  ```
