require 'octokit'
require 'git'
require 'optparse'

GITHUB_TOKEN = ENV['GITHUB_TOKEN']
MERGED_PR_MESSAGE="Merge pull request #"
MERGED_PR_REGEX=/Merge pull request #(\d*)/i

class DeployedPullFinder

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

#IssueFinder.new('~/Projects/TTM/apangea', 'master').get_array_of_pr_nums

Commenter.new.comment('anthlam/gi-web', 2, 'this is a test, this is only a test')
