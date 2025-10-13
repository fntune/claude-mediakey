# Makefile for macOS Media Key Controller

BINARY_NAME = mediakey
SOURCE = mediakey.swift
INSTALL_DIR = $(HOME)/bin
SHELL_RC = $(HOME)/.zshrc

.PHONY: all build install uninstall clean test

all: build

build:
	@echo "Building $(BINARY_NAME)..."
	swiftc $(SOURCE) -o $(BINARY_NAME)
	@echo "Build complete: $(BINARY_NAME)"

install: build
	@echo "Installing to $(INSTALL_DIR)..."
	@mkdir -p $(INSTALL_DIR)
	@cp $(BINARY_NAME) $(INSTALL_DIR)/$(BINARY_NAME)
	@chmod +x $(INSTALL_DIR)/$(BINARY_NAME)
	@echo "Installed to $(INSTALL_DIR)/$(BINARY_NAME)"
	@if ! grep -q '$(INSTALL_DIR)' $(SHELL_RC) 2>/dev/null; then \
		echo "Adding $(INSTALL_DIR) to PATH in $(SHELL_RC)..."; \
		echo 'export PATH="$$HOME/bin:$$PATH"' >> $(SHELL_RC); \
		echo "Added. Run 'source $(SHELL_RC)' or restart your terminal."; \
	else \
		echo "$(INSTALL_DIR) already in PATH"; \
	fi

uninstall:
	@echo "Uninstalling $(BINARY_NAME)..."
	@rm -f $(INSTALL_DIR)/$(BINARY_NAME)
	@echo "Uninstalled"

clean:
	@echo "Cleaning build artifacts..."
	@rm -f $(BINARY_NAME)
	@echo "Clean complete"

test: build
	@echo "Testing $(BINARY_NAME)..."
	@./$(BINARY_NAME) playpause
	@echo "If media paused/played, test passed!"
