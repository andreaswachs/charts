.PHONY: help lint fmt-check template test all changed-charts

# Default target
help:
	@echo "Available targets:"
	@echo "  lint          - Run helm lint on charts"
	@echo "  fmt-check     - Check YAML formatting"
	@echo "  template      - Test charts render with default values"
	@echo "  test          - Run helm unit tests"
	@echo "  all           - Run all checks (lint, fmt-check, template, test)"
	@echo ""
	@echo "For changed charts only (used in CI):"
	@echo "  CHARTS='charts/foo charts/bar' make lint"

# Charts to check - defaults to all, can be overridden
CHARTS ?= $(wildcard charts/*)

# Run helm lint on specified charts
lint:
	@echo "Running helm lint..."
	@failed=0; \
	for chart in $(CHARTS); do \
		if [ -f "$$chart/Chart.yaml" ]; then \
			echo "Linting $$chart..."; \
			if ! helm lint "$$chart"; then \
				failed=1; \
			fi; \
		fi; \
	done; \
	exit $$failed

# Check YAML formatting using yamllint
fmt-check:
	@echo "Checking YAML formatting..."
	@failed=0; \
	for chart in $(CHARTS); do \
		if [ -d "$$chart" ]; then \
			echo "Checking formatting in $$chart..."; \
			if ! yamllint -c .yamllint.yaml "$$chart"; then \
				failed=1; \
			fi; \
		fi; \
	done; \
	exit $$failed

# Test that charts render with default values
template:
	@echo "Testing chart rendering with default values..."
	@failed=0; \
	for chart in $(CHARTS); do \
		if [ -f "$$chart/Chart.yaml" ]; then \
			name=$$(basename "$$chart"); \
			echo "Templating $$chart..."; \
			if ! helm template "$$name" "$$chart" > /dev/null; then \
				failed=1; \
			fi; \
		fi; \
	done; \
	exit $$failed

# Run helm unit tests
test:
	@echo "Running helm unit tests..."
	@failed=0; \
	for chart in $(CHARTS); do \
		if [ -d "$$chart/tests" ]; then \
			echo "Testing $$chart..."; \
			if ! helm unittest "$$chart"; then \
				failed=1; \
			fi; \
		fi; \
	done; \
	exit $$failed

# Run all checks
all: lint fmt-check template test
	@echo "All checks passed!"
