github_commit = function(owner = "timothy-hister", repo, branch = "main", token, file_path, message) {
  file_content = readLines(file_path)
  
  # Step 1: Create a new blob (file content)
  create_blob_url <- paste0("https://api.github.com/repos/", owner, "/", repo, "/git/blobs")
  
  blob_data <- list(
    content = paste(file_content, collapse = "\n"),
    encoding = "utf-8"
  )
  
  blob_post = create_blob_url |>
    httr2::request() |>
    httr2::req_headers(Authorization = paste0("Bearer ", token)) |>
    httr2::req_body_json(blob_data) |>
    httr2::req_perform()
  
  stopifnot(blob_post$status_code == 201)
  blob_sha <- httr2::resp_body_json(blob_post)$sha
  
  
  # Step 2: Get the latest commit SHA of the branch
  get_branch_url <- paste0("https://api.github.com/repos/", owner, "/", repo, "/git/refs/heads/", branch)
  
  latest_commit = get_branch_url |>
    httr2::request() |>
    httr2::req_headers(Authorization = paste0("Bearer ", token)) |>
    httr2::req_perform()
  
  stopifnot(latest_commit$status_code == 200)
  latest_commit_sha <- httr2::resp_body_json(latest_commit)$object$sha
  
  # Step 3: Create a new tree with the new blob
  tree_data <- list(
    base_tree = latest_commit_sha,
    tree = list(
      list(
        path = file_path,
        mode = "100644",
        type = "blob",
        sha = blob_sha
      )
    )
  )
  
  create_tree_url <- paste0("https://api.github.com/repos/", owner, "/", repo, "/git/trees")
  
  tree = create_tree_url |>
    httr2::request() |>
    httr2::req_headers(Authorization = paste0("Bearer ", token)) |>
    httr2::req_body_json(tree_data) |>
    httr2::req_perform()
  
  stopifnot(tree$status_code == 201)
  tree_sha <- httr2::resp_body_json(tree)$sha
  
  
  # Step 4: Create a new commit
  commit_data <- list(
    message = message,
    tree = tree_sha,
    parents = list(latest_commit_sha)
  )
  
  create_commit_url <- paste0("https://api.github.com/repos/", owner, "/", repo, "/git/commits")
  
  commit = create_commit_url |>
    httr2::request() |>
    httr2::req_headers(Authorization = paste0("Bearer ", token)) |>
    httr2::req_body_json(commit_data) |>
    httr2::req_perform()
  
  stopifnot(commit$status_code == 201)
  commit_sha <- httr2::resp_body_json(commit)$sha
  
  # Step 5: Update the branch reference to point to the new commit
  update_ref_url <- paste0("https://api.github.com/repos/", owner, "/", repo, "/git/refs/heads/", branch)
  
  ref_data <- list(
    sha = commit_sha,
    force = FALSE
  )
  
  update = update_ref_url |>
    httr2::request() |>
    httr2::req_headers(Authorization = paste0("Bearer ", token)) |>
    httr2::req_body_json(ref_data) |>
    httr2::req_perform()
  
  stopifnot(update$status_code == 200)
  
  # Success message
  cat("File", file_path, "committed, and pushed to GitHub successfully with message: ", message)
  
}







# 
# 
# message='deleting python_output.txt from github'
# file_path='python_output.txt'
# 
# 
# github_delete = function(owner = "timothy-hister", repo, branch = "main", token, file_path, message) {
#   
#   base_url <- paste0("https://api.github.com/repos/", owner, "/", repo, "/contents/", file_path)
#   
#   # Step 1: Get current file details
#   file_details = base_url |>
#     httr2::request() |>
#     httr2::req_headers(Authorization = paste0("Bearer ", token)) |>
#     httr2::req_perform()
#   
#   stopifnot(file_details$status_code == 200)
#   file_details_sha = httr2::resp_body_json(file_details)$sha
#   
#   # Step 2: Prepare data for deletion
#   delete_body <- list(
#     path = file_path,
#     message = message,
#     branch = branch,
#     sha = file_details_sha
#   )
#   
#   # Step 3: Send DELETE request to delete the file
#   file_details = base_url |>
#     httr2::request() |>
#     httr2::req_headers(Authorization = paste0("Bearer ", token)) |>
#     httr2::req_body_json(delete_body) |>
#     httr2::req_perform()
#   
#   
#   
#   
#   
#   
#   
#   # Step 2: Get the latest commit SHA of the branch
#   get_branch_url <- paste0("https://api.github.com/repos/", owner, "/", repo, "/git/refs/heads/", branch)
#   
#   latest_commit = get_branch_url |>
#     httr2::request() |>
#     httr2::req_headers(Authorization = paste0("Bearer ", token)) |>
#     httr2::req_perform()
#   
#   stopifnot(latest_commit$status_code == 200)
#   latest_commit_sha <- httr2::resp_body_json(latest_commit)$object$sha
#   
#   # Step 3: Create a new tree with the new blob
#   tree_data <- list(
#     base_tree = latest_commit_sha,
#     tree = list(
#       list(
#         path = file_path,
#         mode = "100644",
#         type = "blob",
#         sha = blob_sha
#       )
#     )
#   )
#   
#   create_tree_url <- paste0("https://api.github.com/repos/", owner, "/", repo, "/git/trees")
#   
#   tree = create_tree_url |>
#     httr2::request() |>
#     httr2::req_headers(Authorization = paste0("Bearer ", token)) |>
#     httr2::req_body_json(tree_data) |>
#     httr2::req_perform()
#   
#   stopifnot(tree$status_code == 201)
#   tree_sha <- httr2::resp_body_json(tree)$sha
#   
#   
#   # Step 4: Create a new commit
#   commit_data <- list(
#     message = message,
#     tree = tree_sha,
#     parents = list(latest_commit_sha)
#   )
#   
#   create_commit_url <- paste0("https://api.github.com/repos/", owner, "/", repo, "/git/commits")
#   
#   commit = create_commit_url |>
#     httr2::request() |>
#     httr2::req_headers(Authorization = paste0("Bearer ", token)) |>
#     httr2::req_body_json(commit_data) |>
#     httr2::req_perform()
#   
#   stopifnot(commit$status_code == 201)
#   commit_sha <- httr2::resp_body_json(commit)$sha
#   
#   # Step 5: Update the branch reference to point to the new commit
#   update_ref_url <- paste0("https://api.github.com/repos/", owner, "/", repo, "/git/refs/heads/", branch)
#   
#   ref_data <- list(
#     sha = commit_sha,
#     force = FALSE
#   )
#   
#   update = update_ref_url |>
#     httr2::request() |>
#     httr2::req_headers(Authorization = paste0("Bearer ", token)) |>
#     httr2::req_body_json(ref_data) |>
#     httr2::req_perform()
#   
#   stopifnot(update$status_code == 200)
#   
#   # Success message
#   cat("File", file_path, "committed, and pushed to GitHub successfully with message: ", message)
#   
# }