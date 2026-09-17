MODULES  := $(wildcard modules/*)
EXAMPLES := $(wildcard examples/*)
DIRS     := $(MODULES) $(EXAMPLES)

.PHONY: all fmt fmt-check validate lint test render-check clean

all: fmt-check validate lint test render-check

fmt:
	terraform fmt -recursive

fmt-check:
	terraform fmt -check -recursive -diff

validate:
	@for d in $(DIRS); do \
	  echo "== validate $$d"; \
	  (cd $$d && terraform init -backend=false -input=false >/dev/null && terraform validate) || exit 1; \
	done

lint:
	tflint --init >/dev/null
	@for d in $(DIRS); do echo "== tflint $$d"; tflint --chdir=$$d || exit 1; done

test:
	@for d in $(MODULES); do \
	  if [ -d $$d/tests ]; then echo "== test $$d"; (cd $$d && terraform init -backend=false -input=false >/dev/null && terraform test) || exit 1; fi; \
	done

render-check:
	./scripts/helm-render-check.sh

clean:
	find . -name .terraform -type d -prune -exec rm -rf {} +
	find . -name '*.tfstate*' -delete
