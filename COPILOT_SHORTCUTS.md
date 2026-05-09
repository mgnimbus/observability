# GitHub Copilot CLI - Quick Reference Guide

A comprehensive guide to all shortcuts, commands, and keybindings in the GitHub Copilot CLI. Use this as your daily reference to maximize productivity!

---

## 🎯 Global Shortcuts (Use Anytime)

| Shortcut | Action |
|----------|--------|
| `@` | Mention files and include their contents in context |
| `Ctrl+S` | Run command while preserving input |
| `Shift+Tab` | Cycle through modes (interactive → plan → autopilot) |
| `Ctrl+T` | Toggle model reasoning display |
| `Ctrl+O` | Expand recent timeline (when no input) |
| `Ctrl+E` | Expand all timeline (when no input) |
| `↑` / `↓` | Navigate command history |
| `Ctrl+C` | Cancel / clear input / copy selection |
| `Ctrl+C` × 2 | Exit from the CLI |
| `!` | Execute command in local shell (bypass Copilot) |
| `Esc` | Cancel the current operation |
| `Ctrl+D` | Shutdown |
| `Ctrl+L` | Clear the screen |
| `Ctrl+X` → `O` | Open link from most recent timeline event |

---

## ✏️ Editing Shortcuts (While Typing)

| Shortcut | Action |
|----------|--------|
| `Ctrl+A` | Move to beginning of line |
| `Ctrl+E` | Move to end of line |
| `Ctrl+H` | Delete previous character |
| `Ctrl+W` | Delete previous word |
| `Ctrl+U` | Delete from cursor to beginning of line |
| `Ctrl+K` | Delete from cursor to end of line (joins lines at end) |
| `Meta+←` / `Meta+→` | Move cursor by word |
| `Ctrl+G` | Edit prompt in external editor |
| `Shift+Enter` | Create new line in multiline input |

---

## 🚀 Agent Environment Commands

| Command | Purpose |
|---------|---------|
| `/init` | Initialize Copilot instructions for your repository, or suppress the init suggestion |
| `/agent` | Browse and select from available agents |
| `/skills` | Manage skills for enhanced capabilities |
| `/mcp` | Manage MCP server configuration |
| `/plugin` | Manage plugins and plugin marketplaces |

---

## 🤖 Models & Subagents

| Command | Purpose |
|---------|---------|
| `/model` | Select AI model (Claude Sonnet 4.5, Claude Sonnet 4, GPT-5, etc.) |
| `/delegate` | Send session to GitHub and create a PR |
| `/fleet` | Enable fleet mode for parallel subagent execution |
| `/tasks` | View and manage background tasks (subagents and shell sessions) |

---

## 💻 Code Commands

| Command | Purpose |
|---------|---------|
| `/ide` | Connect to an IDE workspace |
| `/diff` | Review the changes made in the current directory |
| `/pr` | Operate on pull requests for the current branch |
| `/review` | Run code review agent to analyze changes |
| `/lsp` | Manage language server configuration |
| `/terminal-setup` | Configure terminal for multiline input support (Shift+Enter) |

---

## 🔐 Permissions

| Command | Purpose |
|---------|---------|
| `/allow-all` | Enable all permissions (tools, paths, and URLs) |
| `/add-dir` | Add a directory to the allowed list for file access |
| `/list-dirs` | Display all allowed directories for file access |
| `/cwd` | Change working directory or show current working directory |
| `/reset-allowed-tools` | Reset the list of allowed tools |

---

## 📋 Session Management

| Command | Purpose |
|---------|---------|
| `/resume` | Switch to a different session (optionally specify session ID or task ID) |
| `/rename` | Rename the current session, or auto-generate a name from conversation |
| `/context` | Show context window token usage and visualization |
| `/usage` | Display session usage metrics and statistics |
| `/session` | View and manage sessions (use subcommands for details) |
| `/compact` | Summarize conversation history to reduce context window usage |
| `/share` | Share session or research report (markdown, HTML, or GitHub gist) |
| `/copy` | Copy the last response to the clipboard |
| `/rewind` | Rewind the last turn and revert file changes |

---

## ℹ️ Help & Feedback

| Command | Purpose |
|---------|---------|
| `/help` | Show help for interactive commands |
| `/changelog` | Display changelog for CLI versions (add `summarize` for AI summary) |
| `/feedback` | Provide feedback about the CLI |
| `/theme` | View or set color mode |
| `/update` | Update the CLI to the latest version |
| `/version` | Display version information and check for updates |
| `/experimental` | Show available experimental features, or enable/disable experimental mode |
| `/clear` | Abandon this session and start fresh |
| `/instructions` | View and toggle custom instruction files |
| `/streamer-mode` | Toggle streamer mode (hides model names and quota for streaming) |

---

## 🔗 Other Commands

| Command | Purpose |
|---------|---------|
| `/exit` or `/quit` | Exit the CLI |
| `/login` | Log in to Copilot (uses GitHub authentication) |
| `/logout` | Log out of Copilot |
| `/new` | Start a new conversation |
| `/plan` | Create an implementation plan before coding |
| `/research` | Run deep research investigation using GitHub search and web sources |
| `/restart` | Restart the CLI, preserving the current session |
| `/undo` or `/rewind` | Rewind the last turn and revert file changes |
| `/user` | Manage GitHub user list |

---

## 🎯 Pro Tips for DevOps Engineers

### 1. **Multiline Input**
```
/terminal-setup
```
Then use `Shift+Enter` for multiple lines before pressing `Enter` to submit.

### 2. **Context Files**
Use `@` to mention and include files in your context:
```
@Dockerfile @kubernetes.yaml "Why is this pod failing?"
```

### 3. **Fleet Mode for Parallel Work**
Enable fleet mode to dispatch multiple sub-agents in parallel:
```
/fleet
```

### 4. **Monitor Your Quota**
Check your premium requests remaining:
```
/usage
```

### 5. **Review Changes Before Committing**
Always check your changes:
```
/diff
```

### 6. **Run Commands Locally**
Bypass Copilot and run shell commands directly:
```
! kubectl get pods -A
```

### 7. **Plan Complex Tasks**
Use plan mode for structured multi-step work:
```
/plan
```

### 8. **Language Servers**
Set up LSP for intelligent code features:
```
/lsp
```

---

## 📊 Context Window Management

| Command | Info |
|---------|------|
| `/context` | See token usage visualization |
| `/compact` | Reduce context by summarizing history |
| `/clear` | Start fresh session if context gets bloated |

---

## 🔧 Experimental Features

Enable experimental mode for new features:
```
/experimental
```

Current experimental features:
- **Autopilot Mode:** Press `Shift+Tab` to cycle into autopilot, which encourages the agent to continue working until a task is completed.

---

## 🌐 Authentication

### First Time Setup
```
/login
```
Follow on-screen instructions.

### Using Personal Access Token (PAT)
1. Create a PAT at: https://github.com/settings/personal-access-tokens/new
2. Add "Copilot Requests" permission
3. Set environment variable:
   ```
   export GH_TOKEN="your_token_here"
   ```
   or
   ```
   export GITHUB_TOKEN="your_token_here"
   ```

---

## 📂 Custom Instructions

Copilot reads instructions from these locations (in priority order):
- `CLAUDE.md` (current directory)
- `GEMINI.md` (current directory)
- `AGENTS.md` (git root & current directory)
- `.github/instructions/**/*.instructions.md` (git root & current directory)
- `.github/copilot-instructions.md` (git root)
- `$HOME/.copilot/copilot-instructions.md` (user home)
- Environment variable: `COPILOT_CUSTOM_INSTRUCTIONS_DIRS`

---

## 💡 Common Workflows for DevOps

### Troubleshooting EKS Issues
```
@kubeconfig "Help me debug why my pods aren't starting"
/review
```

### Creating Infrastructure Code
```
@existing-manifests "Create a new deployment based on these patterns"
/diff
/pr
```

### Code Review & PR Management
```
/pr
/review
```

### Documentation & Knowledge Base
```
/research "Best practices for Loki log aggregation"
```

### Running Background Tasks
```
/fleet
/tasks
```

---

## 🎨 Customization

### Change Color Theme
```
/theme
```

### Enable Streamer Mode
```
/streamer-mode
```
(Hides model names and quota usage for screen sharing)

---

## 📞 Getting Help

- **In-CLI Help:** `/help`
- **View Changelog:** `/changelog`
- **Send Feedback:** `/feedback`
- **Official Docs:** https://docs.github.com/copilot/concepts/agents/about-copilot-cli
- **Report Issues:** https://github.com/github/copilot-cli

---

## 📈 Usage Tracking

- **Check Usage:** `/usage` (shows premium requests, session metrics)
- **Premium Requests:** Each prompt/command uses 1 premium request
- **Monitor Quota:** Run `/usage` regularly to track your consumption

---

**Last Updated:** 2026-04-05  
**Copilot CLI Version:** 1.0.18

Happy coding! 🚀
