# Variables
LAMBDA_ZIP = lambda_function.zip
PROJECT_ROOT = $(shell pwd)
SRC_DIR = src
TERRAFORM_DIR = .

# Default AWS region
AWS_REGION ?= ap-southeast-2

# Default environment
ENV ?= production

# Colors for terminal output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: all clean deploy package terraform verify install local-test help lint

# Default target
all: help

# Help
help:
	@echo "$(GREEN)Artisan Tiling API Deployment$(NC)"
	@echo "Available commands:"
	@echo "  make install    - Install dependencies"
	@echo "  make clean      - Remove deployment artifacts"
	@echo "  make package    - Create Lambda zip package"
	@echo "  make terraform  - Run Terraform apply"
	@echo "  make deploy     - Full deployment (package + terraform)"
	@echo "  make local-test - Start local development server"
	@echo "  make verify     - Verify environment"
	@echo "  make outputs    - Show Terraform outputs"
	@echo "  make destroy    - Destroy Terraform resources"
	@echo "  make fmt        - Format Terraform files"
	@echo "  make lint       - Lint JavaScript files"

# Verify directories and commands exist
verify:
	@echo "$(GREEN)🔍 Verifying environment...$(NC)"
	@test -d "$(SRC_DIR)" || (echo "$(RED)❌ src directory not found!$(NC)" && exit 1)
	@test -f "$(SRC_DIR)/index.js" || (echo "$(RED)❌ src/index.js not found!$(NC)" && exit 1)
	@test -f "$(SRC_DIR)/app.js" || (echo "$(RED)❌ src/app.js not found!$(NC)" && exit 1)
	@test -d "$(SRC_DIR)/models" || (echo "$(RED)❌ src/models directory not found!$(NC)" && exit 1)
	@test -d "$(SRC_DIR)/controllers" || (echo "$(RED)❌ src/controllers directory not found!$(NC)" && exit 1)
	@test -d "$(SRC_DIR)/routes" || (echo "$(RED)❌ src/routes directory not found!$(NC)" && exit 1)
	@test -d "$(SRC_DIR)/config" || (echo "$(RED)❌ src/config directory not found!$(NC)" && exit 1)
	@which zip > /dev/null || (echo "$(RED)❌ zip command not found! Install with: sudo apt-get install zip$(NC)" && exit 1)
	@which terraform > /dev/null || (echo "$(RED)❌ terraform not found! Please install terraform$(NC)" && exit 1)
	@echo "$(GREEN)✅ Environment verified$(NC)"

# Clean old artifacts
clean:
	@echo "$(GREEN)🧹 Cleaning old deployment files...$(NC)"
	@rm -f $(LAMBDA_ZIP)
	@echo "$(GREEN)✅ Clean completed$(NC)"

# Install dependencies with a clean slate
install:
	@echo "$(GREEN)📦 Removing old node_modules and installing dependencies...$(NC)"
	@rm -rf $(SRC_DIR)/node_modules
	@cd $(SRC_DIR) && npm ci
	@echo "$(GREEN)✅ Dependencies installed$(NC)"

# Package Lambda function
package: clean verify install
	@echo "$(GREEN)📦 Creating $(LAMBDA_ZIP)...$(NC)"
	@cd $(SRC_DIR) && zip -r ../$(LAMBDA_ZIP) . -x "node_modules/*" "test/*" "*.test.js" "local-server.js"
	@cd $(SRC_DIR)/node_modules && zip -r ../../$(LAMBDA_ZIP) . > /dev/null
	@echo "$(GREEN)✅ Lambda package created$(NC)"

# Run Terraform validation
validate:
	@echo "$(GREEN)🔍 Validating Terraform configuration...$(NC)"
	@terraform validate
	@echo "$(GREEN)✅ Terraform configuration is valid$(NC)"

# Run Terraform
terraform: validate
	@echo "$(GREEN)🏗️  Running Terraform...$(NC)"
	@terraform apply -var="environment=$(ENV)" -auto-approve
	@echo "$(GREEN)✅ Terraform deployed$(NC)"

# Full deployment
deploy: package terraform
	@echo "$(GREEN)✅ Deployment completed successfully!$(NC)"

# Show Terraform outputs
outputs:
	@echo "$(GREEN)📊 Terraform outputs:$(NC)"
	@terraform output

# Local development server
local-test:
	@echo "$(GREEN)🚀 Starting local development server...$(NC)"
	@cd $(SRC_DIR) && node local-server.js || (echo "$(YELLOW)ℹ️ local-server.js not found. Creating...$(NC)" && \
		echo "const app = require('./app');\n\nconst PORT = process.env.PORT || 3000;\n\napp.listen(PORT, () => {\n  console.log(\`Server running on port \${PORT}\`);\n});" > $(SRC_DIR)/local-server.js && \
		node $(SRC_DIR)/local-server.js)

# Lint JavaScript files
lint:
	@echo "$(GREEN)🔍 Linting JavaScript files...$(NC)"
	@which eslint > /dev/null || (echo "$(YELLOW)⚠️ ESLint not found. Installing...$(NC)" && npm install -g eslint)
	@cd $(SRC_DIR) && eslint --ext .js .
	@echo "$(GREEN)✅ Linting completed$(NC)"

# Destroy resources
destroy:
	@echo "$(RED)⚠️ WARNING: This will destroy all resources. Are you sure? (yes/no)$(NC)"
	@read -p "" confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "$(YELLOW)🔥 Destroying infrastructure...$(NC)"; \
		terraform destroy -var="environment=$(ENV)" -auto-approve; \
		echo "$(GREEN)✅ Resources destroyed$(NC)"; \
	else \
		echo "$(YELLOW)⚠️ Destroy operation cancelled$(NC)"; \
	fi

# Format Terraform files
fmt:
	@echo "$(GREEN)📝 Formatting Terraform files...$(NC)"
	@terraform fmt
	@echo "$(GREEN)✅ Terraform files formatted$(NC)"