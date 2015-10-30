# gh-release-commenter
This script will compare the git log of the current branch of a repo against a target remote/branch, find all merge commits, pull out the pull request numbers into an array and then use that array to leave a comment on each of those pull requests.

### Setup
```
bundle install
```

### Usage
```
ruby gh_release_commenter.rb --repo <user/repo> --target <remote/branch> --dir <repo local working directory>
