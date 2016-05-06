#!/usr/bin/env ruby

require './lib/merged_pull_request_finder'
require './lib/pull_request_commenter'

def usage
  <<-USAGE.gsub(/^ {4}/, '')
  #{$0} - gathers a list of pull requests being deployed and makes a comment on each to indicate so

    Usage: ruby #{$0} -r <user/repo> -t <remote/branch> -d <repo local working dir> -c <some comment>

    Options:
      -r, --repo:     Github <user/repo> that contains code being deployed.
      -t, --target:   Github <remote/branch> that contains currently deployed code.
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
  pr_nums = []
  pr_nums = MergedPullRequestFinder.new.array_of_pr_nums(options[:dir].to_s, options[:target].to_s)


  # comment on PRs
  puts "Leaving comment on each Pull Request"
  PullRequestCommenter.new(options[:repo]).add_comment_to_issues(pr_nums, options[:comment])
end

if __FILE__ == $0
  main(ARGV)
end
