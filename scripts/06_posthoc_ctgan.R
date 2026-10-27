# post hoc: CTGAN at 3,000 epochs, 20 copies
for (f in list.files("R", full.names = TRUE)) source(f)
d <- read_syn("data/colon.csv")
ref <- read.csv("results/reference.csv")

score <- function(dir, label) {
  files <- sort(list.files(dir, pattern = "^rep_.*csv$", full.names = TRUE))
  rows <- lapply(files, function(p) {
    s <- read_syn(p)
    v <- violations(s)
    s <- repair(s)
    f <- merge(findings(s), ref[, c("finding", "null", "est", "se")], by = "finding",
               suffixes = c("", "_ref"))
    fid <- fidelity(s, d)
    data.frame(f[, c("finding", "est", "p", "lo", "hi", "null", "est_ref", "se_ref")],
               S_pMSE = fid[["S_pMSE"]], ks = fid[["ks"]], km_os = fid[["km_os"]], V1 = v[["V1"]])
  })
  x <- do.call(rbind, rows)
  x$same <- ifelse(x$null, x$p >= 0.05, x$p < 0.05 & sign(x$est) == sign(x$est_ref))
  x$covers <- x$lo <= x$est_ref & x$est_ref <= x$hi
  out <- do.call(rbind, lapply(split(x, x$finding), function(y) data.frame(
    setting = label, copies = nrow(y), finding = y$finding[1], hr_ref = exp(y$est_ref[1]),
    hr_median = exp(median(y$est)), agree = mean(y$same), coverage = mean(y$covers),
    S_pMSE = mean(y$S_pMSE), ks = mean(y$ks), km_os = mean(y$km_os), V1 = mean(y$V1))))
  rownames(out) <- NULL
  out
}

r <- rbind(score("data/synthetic/ctgan", "300 epochs (design)"),
           score("data/synthetic/ctgan_e3000", "3,000 epochs (post hoc)"))
write.csv(r, "results/posthoc_ctgan_epochs.csv", row.names = FALSE)
print(r, digits = 2, row.names = FALSE)
