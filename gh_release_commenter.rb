#!/usr/bin/env ruby

require 'octokit'
require_relative 'lib/pull_request_finder'
require_relative 'lib/pull_request_commenter'

GITHUB_TOKEN = ENV['GITHUB_TOKEN']

def usage
  <<-USAGE.gsub(/^ {4}/, '')
  #{$0} - gathers a list of merged pull requests since some target branch or sha, and makes a comment on each

    Usage: ruby #{$0} -r <user/repo> -t <remote/branch or sha> -c <some comment>

    Options:
      -r, --repo:     Github <user/repo> that contains code being deployed.
      -t, --target:   Github <remote/branch or sha> that contains currently deployed code.
      -c, --comment:  The comment you would like to post.
  USAGE
end

def main(args)
  require 'optparse'

  options = {}

  # parse arguments
  parser = OptionParser.new do |opts|
    opts.on('-r', '--repo REPO')          { |v| options[:repo] = v }
    opts.on('-t', '--target TARGET')      { |v| options[:target] = v }
    opts.on('-c', '--comment COMMENT')    { |v| options[:comment] = v }
  end
  parser.parse(args)

  unless options[:repo] && options[:target] && options[:comment]
    $stderr.puts usage
    Process::exit(1)
  end

  # regex for finding merged pull requests
  merged_pr_regex = /Merge pull request #(\d*)/i

  # setup octokit client
  octokit_client = Octokit::Client.new(:access_token => GITHUB_TOKEN)

  # get list of PRs
  puts "Retrieving list of Pull Requests that have been merged since #{options[:target]}"
  pr_nums = PullRequestFinder.new(octokit_client, options[:repo].to_s, options[:target].to_s, merged_pr_regex).pr_numbers

  # comment on PRs
  puts "Leaving comment on each Pull Request"
  PullRequestCommenter.new(octokit_client, options[:repo]).add_comment_to_issues(pr_nums, options[:comment])
end

if __FILE__ == $0
  main(ARGV)
end
