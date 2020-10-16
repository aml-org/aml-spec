# How to contribute to AML Spec

👍🎉 First off, thanks for taking the time to contribute! 🎉👍

The following is a set of guidelines for contributing to AML Spec:

## How to report a bug
Think you found a bug? Please check the [list of open issues](https://github.com/aml-org/aml-spec/issues) to see if your bug has already been reported. If it hasn't please [submit a new issue](https://github.com/aml-org/aml-spec/issues/new).

Here are a few tips for writing great bug reports:

- Be sure to include a descriptive title, a clear description specifying the problem
- If possible, include examples and other relevant information
- Only include one bug per issue. If you have discovered two bugs, please file two issues

Be sure to include a title, a clear description, as much relevant information as possible and examples if possible.

## Contributing Changes
- Open a new GitHub pull request with the change.
- Ensure the PR description clearly describes the problem and solution. Include the relevant issue number if applicable.
- Before submitting, please read the [Code contributions](#code-contributions) section to know more about the technical contribution requirements.

## Code Contributions
How to set up, run and make changes to the documentation.

### Development Requirements
* Node
* Ruby

### How to run the documentation locally

1. Clone the project

    ```bash
    $ git clone https://github.com/aml-org/aml-spec
    $ gh repo clone aml-org/aml-spec #using github CLI
    ```

2. Install Ruby (if you already have it, skip to step 3)

    ```bash
    $ brew install ruby
    $ ruby --version
    > ruby 2.X.X
    ```

3. Install Bundler

    ```bash
    $ gem install bundler
    # Installs the Bundler gem
    ```

4. Install bundler dependencies

    ```bash
    $ bundle install
    > Fetching gem metadata from https://rubygems.org/............
    > Fetching version metadata from https://rubygems.org/...
    > Fetching dependency metadata from https://rubygems.org/..
    > Resolving dependencies...
    ```

5. Build local Jekyll site

    ```bash
    # in project root directory
    $ bundle exec jekyll serve
    > Configuration file: /Users/octocat/my-site/_config.yml
    >            Source: /Users/octocat/my-site
    >       Destination: /Users/octocat/my-site/_site
    > Incremental build: disabled. Enable with --incremental
    >      Generating...
    >                    done in 0.309 seconds.
    > Auto-regeneration: enabled for '/Users/amirra/mulesoft/aml-spec'
    >    Server address: http://127.0.0.1:4000/
    >  Server running... press ctrl-c to stop.
    ```

6. Navigate to [http://localhost:4000/aml-spec](http://localhost:4000/aml-spec) and the document should display inside your browser. All changes made are auto-reloaded while the server is running.

### How to update documentation
The steps to update documentation are:

1. Update desired markdown file
2. Update documentation index (if necessary)

For example, let's edit the `dialects.md` file with a new topic called 'Example subtitle'. 

- Edit the markdown file
- Add a list element to the `_includes/dialects_menu.html` like the following line of HTML:

    ```html
      <li><a href="#example subtitle">Example Subtitle</a></li>
    ```

#### Notes:  
If you have only modified information already present, there is no need to add a new Subtitle to the index.

For more information and further customization, please refer to the [Jekyll style guide](https://ben.balter.com/jekyll-style-guide/).

GitHub Pages builds the files in the `master` branch. Every change made (i.e. merged PR) updates the public documentation almost instantly.

Private markdown documents can be in the repository without appearing in the documentation if the variable `published` is set to false in the [Front Matter](https://jekyllrb.com/docs/front-matter) of said document.

### Version control branching
- Always branch from `master` branch to ensure you are updated with the latest release.
- Don’t submit unrelated changes in the same branch/pull request.
- If you need to update your branch because of changes in `master` you should always **rebase**, not **merge**.
- You should always be up-to-date with the latest changes in `master`.


## Additional Resources

* [Contributing to Open Source on GitHub](https://guides.github.com/activities/contributing-to-open-source/)
* [Using Pull Requests](https://help.github.com/articles/using-pull-requests/)
* [GitHub Help](https://help.github.com)
