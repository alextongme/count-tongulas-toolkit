#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOS_JSON="$WORKSPACE_DIR/repos.json"

# Defaults
CLONE_ONLY=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Clone all repos in repos.json into the workspace directory, then optionally
bootstrap dependencies.

Options:
  --clone-only     Clone repos without running bootstrap
  -h, --help       Show this help message

Repo groups (from repos.json):
$(jq -r 'to_entries[] | select(.key != "_meta") | "\(.key): \(.value | map(.name) | join(", "))"' "$REPOS_JSON" 2>/dev/null | sed 's/^/  /' || echo "  (run from workspace directory to see groups)")
EOF
    exit 0
}

log()   { echo -e "${BLUE}[workspace]${NC} $*"; }
ok()    { echo -e "${GREEN}[workspace]${NC} $*"; }
warn()  { echo -e "${YELLOW}[workspace]${NC} $*"; }
err()   { echo -e "${RED}[workspace]${NC} $*" >&2; }

# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --clone-only)   CLONE_ONLY=true; shift ;;
        -h|--help)      usage ;;
        *) err "Unknown option: $1"; usage ;;
    esac
done

# --- Prerequisites -----------------------------------------------------------

check_prereq() {
    if ! command -v "$1" &>/dev/null; then
        err "Missing prerequisite: $1"
        return 1
    fi
}

log "Checking prerequisites..."
MISSING=0
for cmd in gh git jq; do
    check_prereq "$cmd" || MISSING=1
done
if [[ $MISSING -eq 1 ]]; then
    err "Install missing prerequisites and retry."
    exit 1
fi

ok "Prerequisites OK"

# Verify gh is authenticated before attempting clones
if ! gh auth status &>/dev/null 2>&1; then
    err "gh is not authenticated. Run: gh auth login"
    exit 1
fi

# --- Clone repos --------------------------------------------------------------

clone_repo() {
    local name="$1" repo="$2" desc="$3"
    local target="$WORKSPACE_DIR/$name"
    if [[ -d "$target/.git" ]]; then
        ok "$name already cloned"
        return 0
    fi
    # Prompt before touching a non-git directory — it may contain user data
    if [[ -d "$target" ]] && [[ ! -d "$target/.git" ]]; then
        warn "$name directory exists but is not a git repo"
        printf "  Options: [r]emove and clone fresh, [s]kip, [q]uit: "
        read -r choice || true
        case "$choice" in
            r|R)
                rm -rf "$target"
                log "Removed $target — cloning fresh..."
                ;;
            q|Q)
                err "Aborted by user"
                exit 1
                ;;
            *)
                warn "Skipping $name"
                return 0
                ;;
        esac
    fi
    log "Cloning $repo ($desc)..."
    if ! gh repo clone "$repo" "$target" -- --quiet; then
        err "Failed to clone $name — skipping"
        return 0
    fi
    ok "Cloned $name"
}

clone_group() {
    local group="$1"
    local count
    count=$(jq -r ".\"$group\" | length" "$REPOS_JSON")
    for ((i = 0; i < count; i++)); do
        local name repo desc
        name=$(jq -r ".\"$group\"[$i].name" "$REPOS_JSON")
        repo=$(jq -r ".\"$group\"[$i].repo" "$REPOS_JSON")
        desc=$(jq -r ".\"$group\"[$i].description" "$REPOS_JSON")
        clone_repo "$name" "$repo" "$desc"
    done
}

# Regenerate .gitignore before cloning so new repos are excluded immediately
log "Updating .gitignore from repos.json..."
{
    echo "# Cloned repos (auto-generated from repos.json — run 'make gitignore' to update)"
    jq -r 'to_entries[] | select(.key != "_meta") | .value[] | .name + "/"' "$REPOS_JSON"
    echo ""
    echo "# OS"
    echo ".DS_Store"
    echo ""
    echo "# Dependencies and secrets"
    echo "node_modules/"
    echo ".env*"
    echo ""
    echo "# Claude Code — ignore local files, track shared config, skills, and agents"
    echo ".claude/*"
    echo "!.claude/CLAUDE.md"
    echo "!.claude/skills/"
    echo "!.claude/agents/"
    echo "!.claude/rules/"
    echo "CLAUDE.local.md"
} > "$WORKSPACE_DIR/.gitignore"
ok ".gitignore updated"

# Clone all groups defined in repos.json
for group in $(jq -r 'keys[] | select(. != "_meta")' "$REPOS_JSON"); do
    log "Cloning $group repos..."
    clone_group "$group"
done

if [[ "$CLONE_ONLY" == true ]]; then
    ok "Clone complete (--clone-only). Skipping bootstrap."
    exit 0
fi

# --- Bootstrap ----------------------------------------------------------------

bootstrap_repo() {
    local name="$1"
    local target="$WORKSPACE_DIR/$name"
    if [[ ! -f "$target/Makefile" ]] && [[ ! -f "$target/package.json" ]]; then
        warn "$name has no Makefile or package.json — skipping bootstrap"
        return 0
    fi
    # Prefer Makefile bootstrap target
    if [[ -f "$target/Makefile" ]] && grep -qE '^bootstrap([[:space:]:]|$)' "$target/Makefile" 2>/dev/null; then
        log "Bootstrapping $name (make bootstrap)..."
        if (cd "$target" && make bootstrap); then
            ok "Bootstrapped $name"
        else
            warn "$name bootstrap failed — continuing"
        fi
        return 0
    fi
    # Fall back to package manager install
    if [[ -f "$target/package.json" ]]; then
        local mgr=""
        if [[ -f "$target/pnpm-lock.yaml" ]]; then
            mgr="pnpm"
        elif [[ -f "$target/yarn.lock" ]]; then
            mgr="yarn"
        elif [[ -f "$target/package-lock.json" ]]; then
            mgr="npm"
        fi
        if [[ -n "$mgr" ]]; then
            log "Bootstrapping $name ($mgr install)..."
            if (cd "$target" && "$mgr" install); then
                ok "Bootstrapped $name"
            else
                warn "$name $mgr install failed — continuing"
            fi
        else
            warn "$name has package.json but no lockfile — skipping install"
        fi
        return 0
    fi
    warn "$name has no bootstrap target — skipping"
}

log "Bootstrapping repos..."
for group in $(jq -r 'keys[] | select(. != "_meta")' "$REPOS_JSON"); do
    count=$(jq -r ".\"$group\" | length" "$REPOS_JSON")
    for ((i = 0; i < count; i++)); do
        name=$(jq -r ".\"$group\"[$i].name" "$REPOS_JSON")
        bootstrap_repo "$name"
    done
done

# --- Recommended Claude Code plugins -----------------------------------------

PLUGIN_NAMES=(
    "code-simplifier@claude-plugins-official"
    "skill-creator@claude-plugins-official"
    "context7@claude-plugins-official"
)
PLUGIN_DESCS=(
    "Reviews changed code for clarity and efficiency"
    "Create, modify, and eval custom Claude Code skills"
    "Fetches up-to-date library docs (React, Express, Flask, etc.)"
)

install_plugin() {
    local plugin="$1"
    local name="${plugin%%@*}"
    if claude plugin list 2>/dev/null | grep -qF "$name"; then
        ok "$name already installed"
    else
        log "Installing $name..."
        claude plugin install "$plugin" && ok "Installed $name" || warn "Failed to install $name"
    fi
}

if command -v claude &>/dev/null; then
    INSTALLED_LIST=$(claude plugin list 2>/dev/null || true)
    PLUGINS_TO_INSTALL=()
    PLUGINS_TO_INSTALL_IDX=()
    for i in "${!PLUGIN_NAMES[@]}"; do
        name="${PLUGIN_NAMES[$i]%%@*}"
        if echo "$INSTALLED_LIST" | grep -qF "$name"; then
            true  # already installed
        else
            PLUGINS_TO_INSTALL+=("${PLUGIN_NAMES[$i]}")
            PLUGINS_TO_INSTALL_IDX+=("$i")
        fi
    done

    echo ""
    log "Recommended Claude Code plugins for this workspace:"
    echo ""
    for i in "${!PLUGIN_NAMES[@]}"; do
        name="${PLUGIN_NAMES[$i]%%@*}"
        installed=""
        if echo "$INSTALLED_LIST" | grep -qF "$name"; then
            installed=" (already installed)"
        fi
        printf "  ${GREEN}%-20s${NC} %s%s\n" "$name" "${PLUGIN_DESCS[$i]}" "$installed"
    done

    if [[ ${#PLUGINS_TO_INSTALL[@]} -eq 0 ]]; then
        echo ""
        ok "All recommended plugins already installed"
    else
        echo ""
        read -rp "$(echo -e "${BLUE}[workspace]${NC}") Install ${#PLUGINS_TO_INSTALL[@]} plugin(s)? [A]ll (default) / [n]one / [c]hoose: " plugin_choice || true
        plugin_choice="${plugin_choice:-a}"
        case "$plugin_choice" in
            [Aa]|"")
                for plugin in "${PLUGINS_TO_INSTALL[@]}"; do
                    install_plugin "$plugin"
                done
                ;;
            [Cc])
                echo ""
                for n in "${!PLUGINS_TO_INSTALL[@]}"; do
                    idx="${PLUGINS_TO_INSTALL_IDX[$n]}"
                    name="${PLUGIN_NAMES[$idx]%%@*}"
                    printf "  ${GREEN}[%d]${NC} %-20s %s\n" "$((n+1))" "$name" "${PLUGIN_DESCS[$idx]}"
                done
                echo ""
                read -rp "$(echo -e "${BLUE}[workspace]${NC}") Enter numbers to install (e.g. 1,3) or 'all': " selections || true
                selections="${selections:-all}"
                if [[ "$selections" == "all" ]]; then
                    for plugin in "${PLUGINS_TO_INSTALL[@]}"; do
                        install_plugin "$plugin"
                    done
                else
                    IFS=',' read -ra PICKS <<< "$selections"
                    for pick in "${PICKS[@]}"; do
                        pick=$(echo "$pick" | tr -d ' ')
                        if [[ "$pick" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#PLUGINS_TO_INSTALL[@]} )); then
                            install_plugin "${PLUGINS_TO_INSTALL[$((pick-1))]}"
                        else
                            warn "Invalid selection: $pick — skipping"
                        fi
                    done
                fi
                ;;
            *)
                warn "Skipped plugin install. You can install later with:"
                for plugin in "${PLUGINS_TO_INSTALL[@]}"; do
                    echo "  claude plugin install $plugin"
                done
                ;;
        esac
    fi
else
    warn "Claude Code CLI not found — skipping plugin recommendations"
fi

# --- Summary ------------------------------------------------------------------

CLONED_COUNT=0
FAILED_COUNT=0
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Workspace setup complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Cloned repos:"
for group in $(jq -r 'keys[] | select(. != "_meta")' "$REPOS_JSON"); do
    count=$(jq -r ".\"$group\" | length" "$REPOS_JSON")
    for ((i = 0; i < count; i++)); do
        name=$(jq -r ".\"$group\"[$i].name" "$REPOS_JSON")
        if [[ -d "$WORKSPACE_DIR/$name" ]]; then
            echo "  $name"
            CLONED_COUNT=$((CLONED_COUNT + 1))
        else
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    done
done
echo ""
if [[ $FAILED_COUNT -gt 0 ]]; then
    warn "$FAILED_COUNT repo(s) failed to clone — check output above"
fi
echo -e "${BOLD}Next steps:${NC}"
echo ""
echo -e "  1. Start Claude Code and fill in .claude/CLAUDE.md with cross-repo context:"
echo -e "     ${CYAN}\$ claude${NC}"
echo ""
echo "     Paste in any cross-repo context you have —"
echo "     which service calls which, shared contracts, deployment order."
echo ""
echo -e "  2. Review and commit the generated CLAUDE.md"
echo ""
echo -e "  ${CYAN}\$ make status${NC}                    # Git status for all repos"
echo -e "  ${CYAN}\$ make update${NC}                    # Pull latest across all repos"
