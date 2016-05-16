class PullRequestCommenter
  def initialize(client, repo)
    @client = client
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
