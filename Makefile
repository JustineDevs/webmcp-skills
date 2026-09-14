# make         Generate index.html from index.bs
# make lint    Check index.bs for warnings and errors
# make watch   Regenerate index.html after any change to index.bs
# make test-adapters  Run browser WebMCP and native adapter smoke tests
# make toolkit        Run deterministic schema, security, eval, and design checks
# make doctor         Run repository and host readiness checks

LOCAL_BIKESHED := $(shell command -v bikeshed 2> /dev/null)

.PHONY: test-adapters toolkit doctor

test-adapters:
	./scripts/test-adapters.sh

toolkit:
	./scripts/webmcp-toolkit.sh schema tests/fixtures/tools.json
	./scripts/webmcp-toolkit.sh security tests/fixtures/tools.json
	./scripts/webmcp-toolkit.sh eval tests/fixtures/evals.json
	./scripts/webmcp-toolkit.sh design tests/fixtures/DESIGN.md

doctor:
	./scripts/webmcp-toolkit.sh doctor

index.html: index.bs
ifndef LOCAL_BIKESHED
	curl https://api.csswg.org/bikeshed/ -f -F file=@$< >$@;
else
	bikeshed spec
endif

ifdef LOCAL_BIKESHED
.PHONY: lint watch

lint: index.bs
	bikeshed --print=plain --dry-run --die-when=late --line-numbers spec $<

watch: index.bs
	@echo 'Browse to file://${PWD}/index.html'
	bikeshed --print=plain watch $<
endif  # LOCAL_BIKESHED
