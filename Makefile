all: install gen_menus serve

install:
	npm install -g markdown-toc
	gem install bundler kramdown
	bundle install

update:
	bundle update

serve:
	bundle exec jekyll serve --livereload

gen_menus:
	./gen_menus.sh

clean:
	rm -rf ./_site/*

.PHONY: all install update serve clean gen_menus
