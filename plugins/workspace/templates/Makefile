WORKSPACE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
REPOS_JSON    := $(WORKSPACE_DIR)/repos.json

# Dynamically discover cloned repo directories.
# Uses repos.json as the source of truth — only directories that exist AND are
# listed in repos.json are included. This avoids hardcoding repo names.
# Guard: skip if repos.json doesn't exist yet or jq is missing.
REPO_NAMES := $(if $(wildcard $(REPOS_JSON)),$(shell command -v jq >/dev/null 2>&1 && jq -r 'to_entries[] | select(.key != "_meta") | .value[] | .name' $(REPOS_JSON) 2>/dev/null))
REPO_DIRS  := $(foreach name,$(REPO_NAMES),$(wildcard $(WORKSPACE_DIR)/$(name)/))

.PHONY: setup setup-full update status search help gitignore

## Clone all repos (default). Use 'make setup-full' to also bootstrap deps.
setup:
	@bash $(WORKSPACE_DIR)/setup.sh --clone-only $(ARGS)

## Full bootstrap — clone repos, install deps
setup-full:
	@bash $(WORKSPACE_DIR)/setup.sh $(ARGS)

## Pull latest on default branch across all cloned repos
update:
	@for dir in $(REPO_DIRS); do \
		name=$$(basename "$$dir"); \
		echo "\033[0;34m[workspace]\033[0m Updating $$name..."; \
		(cd "$$dir" && git pull --ff-only && echo "\033[0;32m[workspace]\033[0m $$name updated") \
		|| echo "\033[1;33m[workspace]\033[0m $$name — pull failed (check output above)"; \
	done

## Show git status for all cloned repos
status:
	@for dir in $(REPO_DIRS); do \
		name=$$(basename "$$dir"); \
		echo ""; \
		echo "=== $$name ==="; \
		(cd "$$dir" && git status --short --branch); \
	done

## Search across all cloned repos (usage: make search QUERY='...')
search:
ifndef QUERY
	@echo "Usage: make search QUERY='pattern'"
	@echo "  Searches file contents across all workspace repos."
else
	@if command -v rg >/dev/null 2>&1; then \
		rg --heading --line-number -- '$(subst ','"'"',$(QUERY))' $(REPO_DIRS) 2>/dev/null || echo "No results found."; \
	else \
		grep -rn --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.pnpm-store --exclude-dir=vendor -- '$(subst ','"'"',$(QUERY))' $(REPO_DIRS) 2>/dev/null || echo "No results found."; \
	fi
endif

## Regenerate .gitignore from repos.json (run after adding repos)
gitignore:
	@if [ ! -f "$(REPOS_JSON)" ]; then echo "repos.json not found" >&2; exit 1; fi
	@echo "# Cloned repos (auto-generated from repos.json — run 'make gitignore' to update)" > $(WORKSPACE_DIR)/.gitignore
	@jq -r 'to_entries[] | select(.key != "_meta") | .value[] | .name + "/"' $(REPOS_JSON) >> $(WORKSPACE_DIR)/.gitignore
	@echo "" >> $(WORKSPACE_DIR)/.gitignore
	@echo "# OS" >> $(WORKSPACE_DIR)/.gitignore
	@echo ".DS_Store" >> $(WORKSPACE_DIR)/.gitignore
	@echo "" >> $(WORKSPACE_DIR)/.gitignore
	@echo "# Dependencies and secrets" >> $(WORKSPACE_DIR)/.gitignore
	@echo "node_modules/" >> $(WORKSPACE_DIR)/.gitignore
	@echo ".env*" >> $(WORKSPACE_DIR)/.gitignore
	@echo "" >> $(WORKSPACE_DIR)/.gitignore
	@echo "# Claude Code — ignore local files, track shared config, skills, and agents" >> $(WORKSPACE_DIR)/.gitignore
	@echo ".claude/*" >> $(WORKSPACE_DIR)/.gitignore
	@echo "!.claude/CLAUDE.md" >> $(WORKSPACE_DIR)/.gitignore
	@echo "!.claude/skills/" >> $(WORKSPACE_DIR)/.gitignore
	@echo "!.claude/agents/" >> $(WORKSPACE_DIR)/.gitignore
	@echo "!.claude/rules/" >> $(WORKSPACE_DIR)/.gitignore
	@echo "CLAUDE.local.md" >> $(WORKSPACE_DIR)/.gitignore
	@echo "Updated .gitignore with $$(jq '[to_entries[] | select(.key != "_meta") | .value[] | .name] | length' $(REPOS_JSON)) repo entries"

## Show available targets
help:
	@echo "Workspace Targets ($(words $(REPO_DIRS)) repos present):"
	@echo ""
	@echo "  make setup              Clone all repos"
	@echo "  make setup-full         Clone + bootstrap deps"
	@echo ""
	@echo "  make update             Pull latest across all cloned repos"
	@echo "  make status             Git status for all repos"
	@echo "  make search QUERY='...' Search across all repos (uses rg if available)"
	@echo "  make gitignore          Regenerate .gitignore from repos.json"
	@echo "  make help               Show this message"
