class PullRequestFinder

  def initialize(octokit_client, repo_name, target_sha, search_regex)
    @client = octokit_client
    @repo = repo_name
    @target = target_sha
    @regex = search_regex
  end

  def pr_numbers
    puts "Getting PR numbers from commit messages"

    matching_commit_messages_since_target.map do |m|
      m.scan(@regex)
    end
      .flatten
      .uniq
  end

  private

  def matching_commit_messages_since_target
    commits_since_target
      .map { |c| c.commit.message }
      .grep(@regex)
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
