require 'octokit'
require 'git'

GITHUB_TOKEN = ENV['GITHUB_TOKEN']

class MergedPullFinder
  MERGED_PR_MESSAGE="Merge pull request #"
  MERGED_PR_REGEX=/Merge pull request #(\d*)/i

  def initialize(working_dir, target)
    @working_dir = working_dir
    @target = target
  end

  def get_array_of_pr_nums
    get_repo
    merge_commits = get_merge_commits_since_last_deploy
    puts get_pr_ids(merge_commits)
  end

  private
  def get_repo
    @repo = Git.open(@working_dir)
    puts @repo.remotes
  end

  def get_merge_commits_since_last_deploy
    @repo.log.between(@target).grep(MERGED_PR_MESSAGE)
  end

  def get_pr_ids(commits)
    commits.map do |c|
      c.message.scan(MERGED_PR_REGEX)
    end
  end
end

class PullCommenter
  def initialize(repo)
    @client = Octokit::Client.new(:access_token => GITHUB_TOKEN)
    @repo = repo
  end

  def add_comment_to_issues(issue_numbers)
    issue_numbers.each do |issue|
      comment(issue, 'This was deployed...')
    end
  end

  def comment(issue_number, content)
    @client.add_comment(repo, issue_number, content)
  end
end

def usage
  <<-USAGE.gsub(/^ {4}/, '')
  #{$0} - gathers a list of pull requests being deployed and makes a comment on each to indicate so

    Usage: ruby #{$0} -r anthlam/gh-release-commenter -t origin/master -d .

    Options:
      -r, --repo:     Github <user>/<repo> that contains code being deployed
      -t, --target:   Github <remote>/<branch> that contains currently deployed code
      -d, --dir:      OPTIONAL: Local working directory of the repo being deployed (default = .)
  USAGE
end

def main(args)
  require 'optparse'

  options = {}

  # default values
  options[:dir] = '.'

  # parse arguments
  parser = OptionParser.new do |opts|
    opts.on('-r', '--repo') { |v| options[:repo] = v }
    opts.on('-t', '--target') { |v| options[:target] = v }
    opts.on('-d', '--dir') { |v| options[:dir] = v }
  end
  parser.parse(args)

  unless options[:repo] && options[:dir] && options[:target]
    $stderr.puts usage
    Process::exit(1)
  end

  # get list of PRs
  pr_nums = []
  pr_nums = MergedPullFinder.new(options[:dir], options[:target]).get_array_of_pr_nums

  # comment on PRs
  PullCommenter.new(options[:repo]).comment(pr_nums)
end

if __FILE__ == $0
  main(ARGV)
end
