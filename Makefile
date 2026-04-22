.PHONY: clean

clean:
	find . -type d -name "states" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "*.toolbox" -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.out" -o -name "*.log" -o -name "*.dot" \
	       -o -name "*.svg" -o -name "*.png" -o -name "*.pdf" \
	       -o -name "*.tex" -o -name "*.dvi" -o -name "*.ps" \
	       -o -name "*.bin" -o -name "*.tlc" -o -name "*.old" \
				 -o -name "*.aux" -o -name "*TTrace*.tla \
	| xargs rm -f 2>/dev/null || true
