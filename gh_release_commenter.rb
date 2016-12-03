#!/usr/bin/env ruby

require 'octokit'
require_relative 'lib/pull_request_finder'
require_relative 'lib/pull_request_commenter'
require_relative 'lib/commit_tagger'

GITHUB_TOKEN = ENV['GITHUB_TOKEN']

def usage
  <<-USAGE.gsub(/^ {4}/, '')
  #{$0} - gathers a list of merged pull requests since some target branch or sha, and makes a comment on each

    Usage: ruby #{$0} -r <user/repo> -s <sha> -c <some comment> -t <tag name>

    Options:
      -c, --comment:  The comment you would like to post.
      -r, --repo:     Github <user/repo> that contains code being deployed.
      -s, --sha:      Github <sha> of commit that is the starting point for searching for merge commits.
      -t, --tag:      (Optional) Name of tag you would like to apply to parent of RC to master merge commit.
  USAGE
end

def main(args)
  require 'optparse'

  options = {}

  # parse arguments
  parser = OptionParser.new do |opts|
    opts.on('-c', '--comment COMMENT')     { |v| options[:comment] = v }
    opts.on('-r', '--repo REPO_FULL_NAME') { |v| options[:repo] = v }
    opts.on('-s', '--sha TARGET_SHA')      { |v| options[:sha] = v }
    opts.on('-t', '--tag TAG_NAME')        { |v| options[:tag] = v }
  end
  parser.parse(args)

  unless options[:repo] && options[:sha] && options[:comment]
    $stderr.puts usage
    Process::exit(1)
  end

  octokit_client = Octokit::Client.new(:access_token => GITHUB_TOKEN)

  merged_pr_regex = /Merge pull request #(\d*)/i
  puts "Retrieving list of pull requests that have been merged since #{options[:sha]}"
  pr_nums = PullRequestFinder.new(octokit_client, options[:repo].to_s, options[:sha].to_s, merged_pr_regex).pr_numbers
  puts "Leaving comment '#{options[:comment]}' on pull requests: #{pr_nums.join(', ')}"
  PullRequestCommenter.new(octokit_client, options[:repo]).add_comment_to_issues(pr_nums, options[:comment])

  CommitTagger.new(octokit_client, options[:repo], 'master').add_tag_to_commit(options[:tag]) if options[:tag]
end

if __FILE__ == $0
  main(ARGV)
end
