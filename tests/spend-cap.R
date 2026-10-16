source("scripts/spend-cap.R")
stopifnot(approved_budget_project("loadings-mcp-test"),
  !approved_budget_project("stable-century-479407-m7"),
  approved_budget_project("stable-century-479407-m7","stable-century-479407-m7"),
  !approved_budget_project("other-project","other-project"))
b <- spend_cap_body("123456789")
b$spendCap <- list(outputState="CONFIGURED")
stopifnot(validate_spend_cap(b,"123456789"))
for (change in c("alerts_only","wrong_project","wrong_service","lifted","enforced","reconciling","too_high","wrong_currency","net_cost")) {
  bad <- b
  switch(change,
    alerts_only = {bad$spendCap <- NULL},
    wrong_project = {bad$budgetFilter$projects <- list("projects/999")},
    wrong_service = {bad$budgetFilter$services <- list("services/OTHER")},
    lifted = {bad$spendCap$outputState <- "AWAITING_NEXT_PERIOD"},
    enforced = {bad$spendCap$outputState <- "ENFORCED"},
    reconciling = {bad$spendCap$reconciling <- TRUE},
    too_high = {bad$amount$specifiedAmount$units <- "500"},
    wrong_currency = {bad$amount$specifiedAmount$currencyCode <- "USD"},
    net_cost = {bad$budgetFilter$creditTypesTreatment <- "INCLUDE_ALL_CREDITS"})
  stopifnot(!isTRUE(validate_spend_cap(bad,"123456789")))
}
cat("Spend-cap gate rejects alerts-only, wrong scope/currency, excessive, unsettled and inactive caps.\n")
