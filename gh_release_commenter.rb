#!/usr/bin/env ruby

require 'git'
require 'octokit'
require_relative 'lib/merged_pull_request_finder'
require_relative 'lib/pull_request_commenter'

GITHUB_TOKEN = ENV['GITHUB_TOKEN']

def usage
  <<-USAGE.gsub(/^ {4}/, '')
  #{$0} - gathers a list of pull requests being deployed and makes a comment on each to indicate so

    Usage: ruby #{$0} -r <user/repo> -t <remote/branch> -d <repo local working dir> -c <some comment>

    Options:
      -r, --repo:     Github <user/repo> that contains code being deployed.
      -t, --target:   Github <remote/branch or sha> that contains currently deployed code.
      -d, --dir:      OPTIONAL: Local working directory of the repo being deployed (default = .)
      -c, --comment:  OPTIONAL: The comment you would like to post. (default = This was released)
  USAGE
end

def main(args)
  require 'optparse'

  options = {}

  # default values
  options[:dir] = '.'
  options[:comment] = 'This was released.'

  # parse arguments
  parser = OptionParser.new do |opts|
    opts.on('-r', '--repo REPO')          { |v| options[:repo] = v }
    opts.on('-t', '--target TARGET')      { |v| options[:target] = v }
    opts.on('-d', '--dir DIR')            { |v| options[:dir] = v }
    opts.on('-c', '--comment COMMENT')    { |v| options[:comment] = v }
  end
  parser.parse(args)

  unless options[:repo] && options[:dir] && options[:target] && options[:comment]
    $stderr.puts usage
    Process::exit(1)
  end

  # get list of PRs
  puts "Retrieving list of Pull Requests that have been merged"
  repo = Git.open(options[:dir].to_s)
  pr_nums = []
  pr_nums = MergedPullRequestFinder.new(repo, options[:target].to_s).merged_pr_numbers


  # comment on PRs
  puts "Leaving comment on each Pull Request"
  octokit_client = Octokit::Client.new(:access_token => GITHUB_TOKEN)
  PullRequestCommenter.new(octokit_client, options[:repo]).add_comment_to_issues(pr_nums, options[:comment])
end

if __FILE__ == $0
  main(ARGV)
end
