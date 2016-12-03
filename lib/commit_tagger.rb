class CommitTagger
  def initialize(octokit_client, repo_name, branch)
    @client = octokit_client
    @repo = repo_name
    @branch = branch
  end

  def add_tag_to_commit(tag_name)
    @client.create_ref(@repo, "tags/#{tag_name}", commit_to_tag)
  end

  private

  def commit_to_tag
    # TODO gets SHA of parent commit of rc to master merge commit
    # too specific to our process, add_tag_to_commit should just take a sha
    @client.commits(@repo, @branch).first.parents.last.sha
  end
end
