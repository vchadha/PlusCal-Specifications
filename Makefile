.PHONY: clean dry-run

CLEAN_DIRS  = -type d \( -name "states" -o -name "*.toolbox" \)
CLEAN_FILES = \( -name "*.out" -o -name "*.log" -o -name "*.dot" \
                 -o -name "*.svg" -o -name "*.png" -o -name "*.pdf" \
                 -o -name "*.tex" -o -name "*.dvi" -o -name "*.ps" \
                 -o -name "*.bin" -o -name "*.tlc" -o -name "*.old" \
								 -o -name "*.aux" -o -name "*TTrace*.tla" \)

dry-run:
	@echo "=== Directories that would be removed ==="
	@find . $(CLEAN_DIRS) -print 2>/dev/null || true
	@echo ""
	@echo "=== Files that would be removed ==="
	@find . $(CLEAN_FILES) -print 2>/dev/null || true

clean:
	@find . $(CLEAN_DIRS) -exec rm -rf {} + 2>/dev/null || true
	@find . $(CLEAN_FILES) | xargs rm -f 2>/dev/null || true
