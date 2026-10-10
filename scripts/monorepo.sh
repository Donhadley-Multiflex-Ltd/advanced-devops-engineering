#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════
# monorepo.sh
# Runs inside an already cloned/existing repository to generate the scaffolded structure and files.
# Usage: Run from anywhere inside your cloned repository: ./monorepo.sh (or ./scripts/monorepo.sh)
# ════════════════════════════════════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# GLOBAL PATHS & REPO ROOT DETECTION
# ═══════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"

# Automatically detect the true root of the git repository, falling back to pwd if not a git repo
project_dir="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# ═══════════════════════════════════════════════════════════════
# COLOURS
# ═══════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LIGHT_BLUE='\033[1;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ═══════════════════════════════════════════════════════════════
# USER / CONFIG
# ═══════════════════════════════════════════════════════════════

current_user=$(whoami)

# Infer project name from repository root folder name
default_project_name=$(basename "$project_dir")

use_husky=false

# ═══════════════════════════════════════════════════════════════
# BANNER
# ═══════════════════════════════════════════════════════════════

echo -e "${BLUE}===================== Monorepo File Generator ==========================${NC}"
echo -e "Username:          ${LIGHT_BLUE}$current_user${NC}"
echo -e "Repository Root:   ${LIGHT_BLUE}$project_dir${NC}"
echo -e "Shell:             ${GREEN}$SHELL${NC}"
echo -e "${BLUE}=======================================================================${NC}"

# ═══════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════

log_success() { echo -e "${GREEN}  ✔ $1${NC}"; }
log_warning() { echo -e "${YELLOW}  ⚠ $1${NC}"; }
log_error()   { echo -e "${RED}  ✖ $1${NC}"; }

safe_copy() {
  local src="$1"
  local dest="$2"

  if [ -f "$src" ]; then
    cp "$src" "$dest"
  else
    log_warning "Missing template: $src"
  fi
}

# ═══════════════════════════════════════════════════════════════
# INPUT HANDLING
# ═══════════════════════════════════════════════════════════════

if [ -n "${1:-}" ]; then
  project_name="$1"
else
  echo -ne "${LIGHT_BLUE}Enter Project Name [default: $default_project_name]: ${NC}"
  read -r project_name
  if [ -z "$project_name" ]; then
    project_name="$default_project_name"
  fi
fi

# ═══════════════════════════════════════════════════════════════
# SECTION CONFIGURATION
# ═══════════════════════════════════════════════════════════════

echo -e "\n${CYAN}Configure API${NC}"
echo "1) Go"
echo "2) Python"
echo "3) Node.js"
echo "4) Spring Boot"
echo "5) Skip"
echo -ne "${LIGHT_BLUE}Your choices (e.g. 1 2): ${NC}"
read -r -a api_choices

echo -e "\n${CYAN}Configure WEB${NC}"
echo "1) App"
echo "2) Dashboard"
echo "3) Supabase"
echo "4) Skip"
echo -ne "${LIGHT_BLUE}Your choices (e.g. 1 2): ${NC}"
read -r -a web_choices

echo -e "\n${CYAN}Configure APP${NC}"
echo "1) Android"
echo "2) iOS"
echo "3) Flutter"
echo "4) Skip"
echo -ne "${LIGHT_BLUE}Your choices (e.g. 1 2): ${NC}"
read -r -a app_choices

echo -e "\n${CYAN}Configure DEPLOY & INFRASTRUCTURE${NC}"
echo "1) Docker"
echo "2) Kubernetes"
echo "3) Helm"
echo "4) Terraform"
echo "5) Ansible"
echo "6) Monitoring"
echo "7) Security"
echo "8) CI/CD"
echo "9) Workflow Automation"
echo "10) Skip"
echo -ne "${LIGHT_BLUE}Your choices (e.g. 1 4 6): ${NC}"
read -r -a deploy_choices

# ═══════════════════════════════════════════════════════════════
# DETECT NODE ECOSYSTEM
# ═══════════════════════════════════════════════════════════════

for choice in "${api_choices[@]}"; do
  if [ "$choice" = "3" ]; then
    use_husky=true
  fi
done

for choice in "${web_choices[@]}"; do
  if [[ "$choice" == "1" || "$choice" == "2" ]]; then
    use_husky=true
  fi
done

# ═══════════════════════════════════════════════════════════════
# ROOT STRUCTURE
# ═══════════════════════════════════════════════════════════════

scaffold_root() {
  mkdir -p "$project_dir"/{docs,scripts}

  if [ "$use_husky" = false ]; then
    mkdir -p "$project_dir/hooks"
  fi

  touch "$project_dir"/{CHANGELOG.md,CONTRIBUTING.md,LICENSE,CODEOWNERS,.dockerignore,.editorconfig}

  # Populate or append project title to README.md
  if [ ! -f "$project_dir/README.md" ]; then
    echo "# $project_name" > "$project_dir/README.md"
    log_success "Created README.md with title: $project_name"
  else
    log_warning "README.md already exists, skipping overwrite."
  fi

  # Populate .gitignore by copying from scripts/.gitignore.local or fallback
  if [ -f "$SCRIPT_DIR/.gitignore.local" ]; then
    safe_copy "$SCRIPT_DIR/.gitignore.local" "$project_dir/.gitignore"
  else
    cat << 'EOF' > "$project_dir/.gitignore"
# ── OS & Environment Files ───────────────────────────────────
.DS_Store
.env
.env.*
!.env.example
# ── IDEs & Editors ───────────────────────────────────────────
.vscode/
.idea/
*.swp
# ── Node.js / Web ────────────────────────────────────────────
node_modules/
dist/
build/
# ── Go ───────────────────────────────────────────────────────
bin/
*.exe
# ── Python ───────────────────────────────────────────────────
__pycache__/
.venv/
venv/
EOF
  fi

  touch "$project_dir/Makefile"

  log_success "Root files and directories generated successfully at repository root"
}

# ═══════════════════════════════════════════════════════════════
# API GENERATORS
# ═══════════════════════════════════════════════════════════════

scaffold_api() {
  echo -e "\n${CYAN}── api/ ────────────────────────────────────────────────${NC}"
  for choice in "${api_choices[@]}"; do
    case $choice in
      1)
        mkdir -p "$project_dir/api"/{cmd,internal,pkg}
        touch "$project_dir/api/main.go" "$project_dir/api/go.mod"
        safe_copy "$SCRIPT_DIR/templates/go/Makefile" "$project_dir/api/Makefile"
        log_success "Go API configured"
        ;;
      2)
        mkdir -p "$project_dir/api"/{src,tests}
        touch "$project_dir/api/src/main.py" "$project_dir/api/requirements.txt"
        log_success "Python API configured"
        ;;
      3)
        mkdir -p "$project_dir/api"/{src,routes,middleware}
        touch "$project_dir/api/src/index.js" "$project_dir/api/package.json"
        safe_copy "$SCRIPT_DIR/templates/node/eslint.config.js" "$project_dir/api/eslint.config.js"
        log_success "Node.js API configured"
        ;;
      4)
        mkdir -p "$project_dir/api/springboot"
        cd "$project_dir/api/springboot" || exit
        curl -fsSL https://start.spring.io/starter.zip \
          -d dependencies=web \
          -d name="$project_name-api" \
          -d type=maven-project \
          -o starter.zip
        unzip -q starter.zip
        rm starter.zip
        cd "$project_dir" || exit
        log_success "Spring Boot API configured"
        ;;
      5) 
        log_warning "API section skipped" 
        ;;
      *) 
        log_error "Unknown API choice: $choice" 
        ;;
    esac
  done
}

# ═══════════════════════════════════════════════════════════════
# WEB GENERATORS
# ═══════════════════════════════════════════════════════════════

scaffold_web() {
  echo -e "\n${CYAN}── web/ ────────────────────────────────────────────────${NC}"
  for choice in "${web_choices[@]}"; do
    case $choice in
      1)
        mkdir -p "$project_dir/web/app"/{public,src}
        touch "$project_dir/web/app/index.html" "$project_dir/web/app/src/main.jsx" "$project_dir/web/app/src/App.jsx"
        safe_copy "$SCRIPT_DIR/templates/react/eslint.config.js" "$project_dir/web/app/eslint.config.js"
        log_success "web/app configured"
        ;;
      2)
        mkdir -p "$project_dir/web/dashboard"/{public,src}
        touch "$project_dir/web/dashboard/index.html" "$project_dir/web/dashboard/src/main.jsx" "$project_dir/web/dashboard/src/App.jsx"
        safe_copy "$SCRIPT_DIR/templates/react/eslint.config.js" "$project_dir/web/dashboard/eslint.config.js"
        log_success "web/dashboard configured"
        ;;
      3)
        mkdir -p "$project_dir/web/supabase"/{migrations,functions}
        touch "$project_dir/web/supabase/config.toml"
        log_success "web/supabase configured"
        ;;
      4) 
        log_warning "Web section skipped" 
        ;;
      *) 
        log_error "Unknown WEB choice: $choice" 
        ;;
    esac
  done
}

# ═══════════════════════════════════════════════════════════════
# APP GENERATORS
# ═══════════════════════════════════════════════════════════════

scaffold_app() {
  echo -e "\n${CYAN}── app/ ────────────────────────────────────────────────${NC}"
  for choice in "${app_choices[@]}"; do
    case $choice in
      1)
        mkdir -p "$project_dir/app/android"/{app/src/main,gradle}
        touch "$project_dir/app/android/build.gradle"
        log_success "Android app configured"
        ;;
      2)
        mkdir -p "$project_dir/app/ios"/{Sources,Resources}
        touch "$project_dir/app/ios/Podfile"
        log_success "iOS app configured"
        ;;
      3)
        mkdir -p "$project_dir/app/flutter"/{lib,test,assets}
        touch "$project_dir/app/flutter/pubspec.yaml"
        log_success "Flutter app configured"
        ;;
      4) 
        log_warning "App section skipped" 
        ;;
      *) 
        log_error "Unknown APP choice: $choice" 
        ;;
    esac
  done
}

# ═══════════════════════════════════════════════════════════════
# DEPLOY GENERATORS
# ═══════════════════════════════════════════════════════════════

scaffold_deploy() {
  echo -e "\n${CYAN}── deploy/ ─────────────────────────────────────────────${NC}"
  for choice in "${deploy_choices[@]}"; do
    case $choice in
      # 1) Docker
      1) 
        mkdir -p "$project_dir/deploy/docker"
        safe_copy "$SCRIPT_DIR/templates/Dockerfile" "$project_dir/deploy/docker/Dockerfile"
        safe_copy "$SCRIPT_DIR/templates/docker-compose.yml" "$project_dir/deploy/docker/docker-compose.yml"
        safe_copy "$SCRIPT_DIR/templates/.dockerignore" "$project_dir/deploy/docker/.dockerignore"
        log_success "Docker configured"
        ;;
      # 2) Kubernetes
      2)
        mkdir -p "$project_dir/deploy/k8s"/{manifests,charts}
        touch "$project_dir/deploy/k8s/manifests/.gitkeep"
        log_success "Kubernetes configured"
        ;;
      # 3) Helm
      3)
        mkdir -p "$project_dir/deploy/helm"/{templates,charts}
        touch "$project_dir/deploy/helm/Chart.yaml" "$project_dir/deploy/helm/values.yaml"
        log_success "Helm configured"
        ;;
      # 4) Terraform
      4)
        mkdir -p "$project_dir/deploy/terraform"/{modules,environments}
        touch "$project_dir/deploy/terraform/main.tf" "$project_dir/deploy/terraform/variables.tf" "$project_dir/deploy/terraform/outputs.tf"
        log_success "Terraform configured"
        ;;
      # 5) Ansible
      5)
        mkdir -p "$project_dir/deploy/ansible"/{playbooks,roles}
        touch "$project_dir/deploy/ansible/inventory.ini" "$project_dir/deploy/ansible/playbooks/site.yml" "$project_dir/deploy/ansible/roles/.gitkeep"
        log_success "Ansible configured"
        ;;
      # 6) Monitoring
      6)
        mkdir -p "$project_dir/deploy/monitoring"/{prometheus,grafana} && mkdir -p "$project_dir/deploy/monitoring/grafana/dashboards"
        touch "$project_dir/deploy/monitoring/prometheus/prometheus.yml" "$project_dir/deploy/monitoring/grafana/dashboards/.gitkeep"
        log_success "Monitoring configured"
        ;;
      # 7) Security
      7)
        mkdir -p "$project_dir/deploy/security"/{vault,certs}
        touch "$project_dir/deploy/security/vault/.gitkeep" "$project_dir/deploy/security/certs/.gitkeep"
        touch "$project_dir/deploy/security/.gitkeep"
        log_success "Security configured"
        ;;
      # 8) CI/CD
      8)
        mkdir -p "$project_dir/deploy/pipelines"
        touch "$project_dir/deploy/pipelines/.gitkeep"
        log_success "CI/CD configured"
        ;;
      # 9) Workflow Automation
      9)
        mkdir -p "$project_dir/deploy/argocd"
        touch "$project_dir/deploy/argocd/.gitkeep"
        log_success "Workflow Automation configured"
        ;;
      # 10) Skip
      10) 
        log_warning "Deploy section skipped" 
        ;;
      *) 
        log_error "Unknown DEPLOY choice: $choice" 
        ;;
    esac
  done
}

# ═══════════════════════════════════════════════════════════════
# DOCS
# ═══════════════════════════════════════════════════════════════

scaffold_docs() {
  echo -e "\n${CYAN}── docs/ ───────────────────────────────────────────────${NC}"
  mkdir -p "$project_dir/docs"/{architecture,api,guides}
  touch "$project_dir/docs/architecture/.gitkeep" "$project_dir/docs/api/.gitkeep" "$project_dir/docs/guides/.gitkeep"
  log_success "docs configured"
}

# ═══════════════════════════════════════════════════════════════
# HUSKY SETUP
# ═══════════════════════════════════════════════════════════════

setup_husky() {
  echo -e "\n${BLUE}Setting up Husky...${NC}"
  cd "$project_dir" || exit
  npm init -y
  npm install --save-dev husky
  npx husky init
  chmod +x .husky/pre-commit
  log_success "Husky configured"
}

# ═══════════════════════════════════════════════════════════════
# RUN
# ═══════════════════════════════════════════════════════════════

echo -e "\n${BLUE}Generating files in repository root...${NC}"

scaffold_root
scaffold_api
scaffold_web
scaffold_app
scaffold_deploy
scaffold_docs

if [ "$use_husky" = true ]; then
  setup_husky
fi

echo -e "${BLUE}=======================================================================${NC}"
echo -e "\n${GREEN}✅ Files generated successfully inside repository root: $project_dir${NC}"
echo -e "${BLUE}=======================================================================${NC}"