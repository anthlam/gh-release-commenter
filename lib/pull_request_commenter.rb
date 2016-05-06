require 'octokit'

class PullRequestCommenter
  GITHUB_TOKEN = ENV['GITHUB_TOKEN']

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
