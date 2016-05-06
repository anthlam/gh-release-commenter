require '../lib/merged_pull_request_finder'
require 'test/unit'

class MergedPullRequestFinderTest < Test::Unit::TestCase
  def setup
    @subject = MergedPullRequestFinder.new
  end

  def test_duplicate_issue_numbers_are_removed
    commit_messages = [
      "This is just a random commit",
      "Merge pull request #1 from blah to master",
      "Merge pull request #2 from test to master",
      "Another non-merge commit",
      "Revert 'Merge pull request #1 from blah to master'",
      "merge Pull request #3 from hello to master"
    ]

    actual = @subject.pr_numbers(commit_messages)
    expected = ["1", "2", "3"]

    assert_equal actual, expected
  end
end