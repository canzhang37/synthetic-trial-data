# the four findings, refitted on any copy

num <- function(x) as.numeric(as.character(x))

FINDINGS <- data.frame(
  finding = c("F1", "F2", "F3", "F4"),
  label = c("recurrence, Lev+5FU vs Obs", "death, Lev+5FU vs Obs",
            "recurrence, Lev vs Obs", "death, more than 4 nodes (adjusted)"),
  null = c(FALSE, FALSE, TRUE, FALSE))

findings <- function(d) {
  a <- data.frame(rx = d$rx, sex = num(d$sex), age = d$age, obstruct = num(d$obstruct),
                  differ = num(d$differ), extent = num(d$extent), node4 = num(d$node4),
                  rec_time = d$rec_time, rec = num(d$rec_status),
                  os_time = d$os_time, os = num(d$os_status))
  fit <- function(f) tryCatch(survival::coxph(f, data = a), error = function(e) NULL)
  rec <- fit(survival::Surv(rec_time, rec) ~ rx)
  os <- fit(survival::Surv(os_time, os) ~ rx)
  adj <- fit(survival::Surv(os_time, os) ~ rx + node4 + extent + obstruct + differ + age + sex)
  pick <- function(f, term) {
    b <- if (is.null(f)) NA else unname(coef(f)[term])
    se <- if (is.null(f) || is.na(b)) NA else sqrt(vcov(f)[term, term])
    c(est = b, se = se)
  }
  r <- rbind(pick(rec, "rxLev+5FU"), pick(os, "rxLev+5FU"), pick(rec, "rxLev"), pick(adj, "node4"))
  r <- data.frame(finding = FINDINGS$finding, r)
  r$p <- 2 * pnorm(-abs(r$est / r$se))
  r$lo <- r$est - qnorm(0.975) * r$se
  r$hi <- r$est + qnorm(0.975) * r$se
  r
}
