class MergedPullRequestFinder
  MERGED_PR_MESSAGE="Merge pull request #"
  MERGED_PR_REGEX=/Merge pull request #(\d*)/i

  def initialize(repo, target)
    @repo = repo
    @target = target
  end

  def merged_pr_numbers
    merge_commits_since_target
    commit_messages
    pr_numbers
  end

  private

  def merge_commits_since_target
    puts "Diffing git log, searching for commit messages containing '#{MERGED_PR_MESSAGE}'"
    @merge_commits = @repo.log.between(@target).grep(MERGED_PR_MESSAGE)
  end

  def commit_messages
    @commit_messages = @merge_commits.map do |c|
      c.message
    end
  end

  def pr_numbers
    puts "Getting PR numbers from commit messages"
    @commit_messages.map do |m|
      m.scan(MERGED_PR_REGEX)
    end.flatten.uniq
  end
end
