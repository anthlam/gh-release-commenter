require 'git'

class MergedPullRequestFinder
  MERGED_PR_MESSAGE="Merge pull request #"
  MERGED_PR_REGEX=/Merge pull request #(\d*)/i

  def array_of_pr_nums(working_dir, target)
    repo(working_dir)
    merge_commits = merge_commits_since(target)
    commit_messages = commit_messages(merge_commits)
    pr_numbers(commit_messages)
  end

  def repo(working_dir)
    @repo = Git.open(working_dir)
  end

  def merge_commits_since(target)
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
