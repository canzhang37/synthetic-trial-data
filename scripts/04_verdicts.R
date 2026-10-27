# checks C1 to C6 from docs/design.md
for (f in list.files("R", full.names = TRUE)) source(f)
ref <- read.csv("results/reference.csv")
est <- read.csv("results/replicates.csv")
fid <- read.csv("results/fidelity.csv")
methods <- c("bootstrap", "cart", "bn", "ctgan")

e <- merge(est, ref[, c("finding", "label", "null", "est", "se")], by = "finding",
           suffixes = c("", "_ref"))
same <- with(e, ifelse(null, !is.na(p) & p >= 0.05,
                       !is.na(p) & p < 0.05 & sign(est) == sign(est_ref)))
e$same <- same
e$covers <- with(e, !is.na(lo) & lo <= est_ref & est_ref <= hi)

by_mf <- split(e, list(e$method, e$finding), drop = TRUE)
fs <- do.call(rbind, lapply(by_mf, function(x) data.frame(
  method = x$method[1], finding = x$finding[1], label = x$label[1], n = nrow(x),
  failed = sum(is.na(x$est)), hr_ref = exp(x$est_ref[1]),
  hr_median = exp(median(x$est, na.rm = TRUE)),
  agree = mean(x$same),
  bias_se = abs(median(x$est, na.rm = TRUE) - x$est_ref[1]) / x$se_ref[1],
  coverage = mean(x$covers),
  sd = sd(x$est, na.rm = TRUE),
  aug_width = median(x$aug_se / x$se_ref[1], na.rm = TRUE),
  aug_shift_se = median((x$aug_est - x$est_ref[1]) / x$se_ref[1], na.rm = TRUE))))
boot_sd <- setNames(fs$sd[fs$method == "bootstrap"], fs$finding[fs$method == "bootstrap"])
fs$sd_ratio <- fs$sd / boot_sd[fs$finding]
fs$method <- factor(fs$method, methods)
fs <- fs[order(fs$method, fs$finding), ]
rownames(fs) <- NULL
write.csv(fs, "results/summary_findings.csv", row.names = FALSE)

fm <- aggregate(. ~ method, data = fid[, setdiff(names(fid), "rep")], FUN = mean)
fm <- fm[match(methods, fm$method), ]
write.csv(fm, "results/summary_fidelity.csv", row.names = FALSE)

v <- list()
add <- function(...) v[[length(v) + 1]] <<- data.frame(...)
for (i in seq_len(nrow(fs))) {
  r <- fs[i, ]
  add(method = r$method, check = "C1", finding = r$finding, value = sprintf("%.0f%%", 100 * r$agree), met = r$agree >= 0.8)
  add(method = r$method, check = "C2", finding = r$finding, value = sprintf("%.2f SE", r$bias_se), met = r$bias_se <= 0.5)
  add(method = r$method, check = "C3", finding = r$finding, value = sprintf("%.0f%%", 100 * r$coverage), met = r$coverage >= 0.9)
  if (r$method != "bootstrap")
    add(method = r$method, check = "C4", finding = r$finding, value = sprintf("%.2f x", r$sd_ratio), met = r$sd_ratio <= 1.5)
}
for (m in setdiff(methods, "bootstrap")) {
  x <- fm[fm$method == m, ]
  add(method = m, check = "C5", finding = "V1", value = sprintf("%.1f%%", 100 * x$V1), met = x$V1 <= 0.01)
  add(method = m, check = "C5", finding = "V2", value = sprintf("%.1f%%", 100 * x$V2), met = x$V2 <= 0.01)
  add(method = m, check = "C6", finding = "exact copies", value = sprintf("%.1f%%", 100 * x$exact), met = x$exact <= 0.05)
}
v <- do.call(rbind, v)
write.csv(v, "results/verdicts.csv", row.names = FALSE)

repro <- sapply(methods, function(m) all(v$met[v$method == m & v$check %in% c("C1", "C2", "C3")]))
cat("\nreproduces all four findings (C1-C3):\n")
print(repro)
cat("\nper finding (C1-C3 all met):\n")
w <- v[v$check %in% c("C1", "C2", "C3"), ]
print(tapply(w$met, list(w$method, w$finding), all)[methods, ])
cat("\n")
print(fs[, c("method", "finding", "hr_ref", "hr_median", "agree", "bias_se", "coverage", "sd_ratio",
             "aug_width")], digits = 2, row.names = FALSE)
cat("\n")
print(fm, digits = 3, row.names = FALSE)
