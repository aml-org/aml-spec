all: install serve

install:
	npm install -g markdown-toc
	gem install bundler
	bundle install

update:
	bundle update

serve: gen_menus
	bundle exec jekyll serve --livereload

gen_menus:
	./gen_menus.sh

clean:
	rm -rf ./_site/*

.PHONY: all install update serve clean gen_menus
