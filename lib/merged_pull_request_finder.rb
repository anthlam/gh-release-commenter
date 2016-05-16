class MergedPullRequestFinder
  MERGED_PR_MESSAGE="Merge pull request #"
  MERGED_PR_REGEX=/Merge pull request #(\d*)/i

  def initialize(repo, last_deploy)
    @repo = repo
    @target = last_deploy
  end

  def merged_pr_numbers
    @merge_commits = merge_commits_since_last_deploy
    @commit_messages = commit_messages
    pr_numbers
  end

  private

  def merge_commits_since_last_deploy
    puts "Diffing git log, searching for commits with '#{MERGED_PR_MESSAGE}'"
    @repo.log.between(@target).grep(MERGED_PR_MESSAGE)
  end

  def commit_messages
    @merge_commits.map do |c|
      c.message
    end
  end

  def pr_numbers
    puts "Getting array of PR numbers from messages in list of commits"
    @commit_messages.map do |m|
      m.scan(MERGED_PR_REGEX)
    end.flatten.uniq
  end
end
