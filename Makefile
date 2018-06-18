all: install serve

install:
	npm install -g markdown-toc
	gem install bundler
	bundle install

update:
	bundle update

serve:
	bundle exec jekyll serve --livereload

clean:
	rm -rf ./_site/*

.PHONY: all install update serve clean
