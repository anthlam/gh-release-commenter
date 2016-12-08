#!/usr/bin/env ruby

require 'octokit'
require_relative 'lib/pull_request_finder'
require_relative 'lib/pull_request_commenter'
require_relative 'lib/commit_tagger'

GITHUB_TOKEN = ENV['GITHUB_TOKEN']

def usage
  <<-USAGE.gsub(/^ {4}/, '')

  #{$0} - gathers a list of Github merged pull requests since some target sha, and makes a comment on each.
  Also has the optional capability of tagging a specific commit.

  Usage: ruby #{$0} -r <user/repo> --comment_sha <sha> -c <some comment> [-t <tag name> --tag_sha <sha>]

  Options:
  -c,  --comment:  The comment you would like to post on pull requests.
  -r,  --repo:     User/repo that contains code being deployed.
  --comment_sha:   Sha of commit that begins range of search for merge commits between then and now.
  -t,  --tag:      (Optional) Name of tag you would like to apply to commit. NO SPACES ALLOWED.
  --tag_sha:       (Optional if tag not set) Sha of commit that you would like to tag.
  USAGE
end

def main(args)
  require 'optparse'

  options = {}

  parser = OptionParser.new do |opts|
    opts.on('-c', '--comment COMMENT')      { |v| options[:comment] = v }
    opts.on('-r', '--repo REPO_FULL_NAME')  { |v| options[:repo] = v }
    opts.on('--comment_sha COMMENT_SHA')    { |v| options[:comment_sha] = v }
    opts.on('-t', '--tag TAG_NAME')         { |v| options[:tag] = v }
    opts.on('--tag_sha TAG_SHA')            { |v| options[:tag_sha] = v }
  end
  parser.parse(args)

  if (options[:repo].nil? || options[:repo].empty?) || (options[:comment_sha].nil? || options[:comment_sha].empty?) || (options[:comment].nil? || options[:comment].empty?)
    puts "  ERROR: --repo, --comment_sha, and --comment are required!"
    $stderr.puts usage
    Process::exit(1)
  end

  if (!options[:tag].nil? && (options[:tag_sha].nil? || options[:tag_sha].empty?)) || ((options[:tag].nil? || options[:tag].empty?) && !options[:tag_sha].nil?)
    puts "  ERROR: --tag and --tag_sha must both be set!"
    $stderr.puts usage
    Process::exit(1)
  end

  if options[:tag] =~ /\s/
    puts "  ERROR: --tag may not contain spaces!"
    $stderr.puts usage
    Process::exit(1)
  end

  octokit_client = Octokit::Client.new(:access_token => GITHUB_TOKEN)

  merged_pr_regex = /Merge pull request #(\d*)/i
  puts "Retrieving list of pull requests that have been merged since #{options[:comment_sha]}"
  pr_nums = PullRequestFinder.new(octokit_client, options[:repo].to_s, options[:comment_sha].to_s, merged_pr_regex).pr_numbers
  puts "Leaving comment '#{options[:comment]}' on pull requests: #{pr_nums.join(', ')}"
  PullRequestCommenter.new(octokit_client, options[:repo]).add_comment_to_issues(pr_nums, options[:comment])

  if options[:tag] && options[:tag_sha]
    puts "Tagging commit #{options[:tag_sha]}"
    CommitTagger.new(octokit_client, options[:repo]).add_tag_to_commit(options[:tag], options[:tag_sha])
  end
end

if __FILE__ == $0
  main(ARGV)
end
