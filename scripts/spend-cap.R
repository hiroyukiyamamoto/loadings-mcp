# Official Cloud Billing Budget API. Default mode only prints a proposed request.
if (dir.exists(".library")) .libPaths(c(normalizePath(".library"), .libPaths()))
spend_cap_body <- function(project_number, amount = 400L) {
  stopifnot(grepl("^[0-9]+$", project_number), length(amount)==1L,
            is.finite(amount), amount > 0, amount <= 500, amount==floor(amount))
  list(displayName="loadings-mcp monthly Cloud Run spend cap",
    budgetFilter=list(projects=list(paste0("projects/",project_number)),
      services=list("services/152E-C115-5142"), calendarPeriod="MONTH",
      creditTypesTreatment="EXCLUDE_ALL_CREDITS"),
    amount=list(specifiedAmount=list(currencyCode="JPY", units=as.character(amount))),
    thresholdRules=lapply(c(.5,.8,1), function(x) list(thresholdPercent=x,spendBasis="CURRENT_SPEND")),
    notificationsRule=list(enableProjectLevelRecipients=TRUE),
    spendCap=list(inputState="CONFIGURED"))
}
validate_spend_cap <- function(budget, project_number, maximum = 400L) {
  f <- budget$budgetFilter; a <- budget$amount$specifiedAmount; s <- budget$spendCap
  identical(unlist(f$projects, use.names=FALSE), paste0("projects/",project_number)) &&
    identical(unlist(f$services, use.names=FALSE), "services/152E-C115-5142") &&
    identical(f$calendarPeriod,"MONTH") && identical(f$creditTypesTreatment,"EXCLUDE_ALL_CREDITS") &&
    identical(a$currencyCode,"JPY") && length(a$units)==1L &&
    is.finite(suppressWarnings(as.numeric(a$units))) && as.numeric(a$units)>0 &&
    (as.numeric(a$units) + if(is.null(a$nanos)) 0 else a$nanos/1e9) <= maximum &&
    identical(s$outputState,"CONFIGURED") && !isTRUE(s$reconciling)
}
run_spend_cap <- function(mode = "plan") {
  if (!mode %in% c("plan","create","verify")) stop("Use plan, create or verify")
  project <- Sys.getenv("GOOGLE_CLOUD_PROJECT")
  account <- Sys.getenv("BILLING_ACCOUNT_ID")
  if (!grepl("^loadings-mcp-[a-z0-9-]+$",project)) stop("Use a dedicated loadings-mcp-* project")
  if (!grepl("^[0-9A-F]{6}-[0-9A-F]{6}-[0-9A-F]{6}$",account)) stop("Set BILLING_ACCOUNT_ID")
  cli <- function(args) {
    command <- if (.Platform$OS.type=="windows") Sys.which("gcloud.cmd") else Sys.which("gcloud")
    if (!nzchar(command)) stop("gcloud CLI required")
    out <- suppressWarnings(system2(command, shQuote(args), stdout=TRUE, stderr=TRUE))
    if (!is.null(attr(out,"status")) && attr(out,"status")!=0) stop("gcloud preflight failed; inspect CLI authentication and permissions")
    paste(out,collapse="\n")
  }
  number <- cli(c("projects","describe",project,"--format=value(projectNumber)","--quiet"))
  body <- spend_cap_body(number)
  if (mode=="plan") {cat(jsonlite::toJSON(body,auto_unbox=TRUE,pretty=TRUE),"\n");return(invisible(body))}
  if (mode=="create" && Sys.getenv("APPROVE_BUDGET_CREATE")!="yes") stop("Budget creation requires explicit approval; set APPROVE_BUDGET_CREATE=yes only after approval")
  token <- cli(c("auth","print-access-token","--quiet"))
  request <- httr2::request(paste0("https://billingbudgets.googleapis.com/v1/billingAccounts/",account,"/budgets")) |>
    httr2::req_auth_bearer_token(token) |> httr2::req_headers(`x-goog-user-project`=project) |> httr2::req_timeout(30)
  billing <- httr2::request(paste0("https://cloudbilling.googleapis.com/v1/projects/",project,"/billingInfo")) |>
    httr2::req_auth_bearer_token(token) |> httr2::req_timeout(30) |> httr2::req_perform() |> httr2::resp_body_json()
  if (!isTRUE(billing$billingEnabled) || billing$billingAccountName!=paste0("billingAccounts/",account)) stop("Project billing account mismatch")
  if (mode=="create") {
    # No retries on mutation. Duplicate scopes are rejected by Google's API.
    created <- request |> httr2::req_body_json(body,auto_unbox=TRUE) |> httr2::req_perform() |> httr2::resp_body_json()
    cat("Created budget: ",created$name,"\n",sep="")
  }
  found <- list(); page <- ""
  repeat {
    response <- request |> httr2::req_url_query(pageSize=100,pageToken=page) |> httr2::req_perform() |> httr2::resp_body_json()
    found <- c(found,response$budgets)
    page <- response$nextPageToken
    if (is.null(page) || !nzchar(page)) break
  }
  valid <- Filter(function(b) isTRUE(validate_spend_cap(b,number)),found)
  if(length(valid)!=1L) stop("No unique, settled CONFIGURED Cloud Run spend cap <= JPY 400 for this project; DO NOT DEPLOY/PUBLISH")
  cat("Verified configured spend cap: ",valid[[1]]$name," (JPY ",valid[[1]]$amount$specifiedAmount$units,
      "). This is not a total billing guarantee or a tested enforcement event.\n",sep="")
}
if (sys.nframe()==0L) {
  args <- commandArgs(trailingOnly=TRUE)
  run_spend_cap(if(length(args)) args[[1]] else "plan")
}
