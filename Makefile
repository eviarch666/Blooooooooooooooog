.PHONY : all deploy

all: deploy

dependencies:
	@if ! command -v hexo > /dev/null; then \
		echo "Installing Hexo..."; \
		npm install hexo-cli -g; \
	fi
	npm install
	bash .scripts/install-pandoc.sh

PATH := $(pwd)/$(PANDOC_PATH):$(PATH)
PANDOC_PATH := tmp/bin

deploy: dependencies
	@echo "Building site..."
	hexo generate

preview:
	@echo "Starting server..."
	hexo server

clean:
	rm -rf public
