require 'octokit'
require 'git'

GITHUB_TOKEN = ENV['GITHUB_TOKEN']

class MergedPullFinder
  MERGED_PR_MESSAGE="Merge pull request #"
  MERGED_PR_REGEX=/Merge pull request #(\d*)/i

  def array_of_pr_nums(working_dir, target)
    repo(working_dir)
    merge_commits = merge_commits_since_target(target)
    commit_messages = commit_messages(merge_commits)
    pr_numbers(commit_messages)
  end

  def repo(working_dir)
    @repo = Git.open(working_dir)
  end

  def merge_commits_since_target(target)
    puts "Diffing git log, searching for commits with '#{MERGED_PR_MESSAGE}'"
    @repo.log.between(target).grep(MERGED_PR_MESSAGE)
  end

  def commit_messages(commits)
    commits.map do |c|
      c.message
    end
  end

  def pr_numbers(messages)
    puts "Getting array of PR numbers from messages in list of commits"
    messages.map do |m|
      m.scan(MERGED_PR_REGEX)
    end.flatten.uniq
  end
end

class PullCommenter
  def initialize(repo)
    @client = Octokit::Client.new(:access_token => GITHUB_TOKEN)
    @repo = repo
  end

  def add_comment_to_issues(issue_numbers, comment)
    issue_numbers.each do |issue|
      puts "Posting comment to ##{issue} in #{@repo}"
      comment(issue, comment)
    end
  end

  private
  def comment(issue_number, content)
    @client.add_comment(@repo, issue_number, content.to_s)
  end
end

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
  pr_nums = MergedPullFinder.new.array_of_pr_nums(options[:dir].to_s, options[:target].to_s)


  # comment on PRs
  puts "Leaving comment on each Pull Request"
  PullCommenter.new(options[:repo]).add_comment_to_issues(pr_nums, options[:comment])
end

if __FILE__ == $0
  main(ARGV)
end
