class MergedPullRequestFinder
  MERGED_PR_REGEX=/Merge pull request #(\d*)/i

  def initialize(octokit_client, repo_name, target_sha)
    @client = octokit_client
    @repo = repo_name
    @target = target_sha
  end

  def merged_pr_numbers
    puts "Getting PR numbers from commit messages"

    merge_commit_messages_since_target.map do |m|
      m.scan(MERGED_PR_REGEX)
    end
      .flatten
      .uniq
  end

  private

  def merge_commit_messages_since_target
    commits_since_target
      .map { |c| c.commit.message }
      .grep(MERGED_PR_REGEX)
  end

  def commits_since_target
    commits = @client.commits_since(@repo, target_date)
    commits.pop  # Because the last commit has likely already been commented on
    commits
  end

  def target_date
    @client
      .commit(@repo, @target)
      .commit
      .committer
      .date
  end
end
