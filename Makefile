watch:
	coffee -w -b --no-header -o ./lib/ ./src/*.coffee
publish:
	npm publish .
