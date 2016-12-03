class CommitTagger
  def initialize(octokit_client, repo_name)
    @client = octokit_client
    @repo = repo_name
  end

  def add_tag_to_commit(tag_name, commit_sha)
    @client.create_ref(@repo, "tags/#{tag_name}", commit_sha)
  end
end
