# refit the findings and score every data set
for (f in list.files("R", full.names = TRUE)) source(f)
d <- read_syn("data/colon.csv")
methods <- c("bootstrap", "cart", "bn", "ctgan")

est <- list()
fid <- list()
for (m in methods) {
  files <- sort(list.files(file.path("data", "synthetic", m), pattern = "^rep_.*csv$", full.names = TRUE))
  t <- system.time(for (p in files) {
    r <- as.integer(sub("rep_(\\d+)\\.csv", "\\1", basename(p)))
    s <- read_syn(p)
    v <- violations(s)
    s <- repair(s)
    f <- findings(s)
    aug <- findings(rbind(d, s))
    est[[length(est) + 1]] <- data.frame(method = m, rep = r, f,
                                         aug_est = aug$est, aug_se = aug$se)
    fid[[length(fid) + 1]] <- data.frame(method = m, rep = r, t(v), t(fidelity(s, d)))
  })
  cat(m, ":", length(files), "data sets in", round(t[["elapsed"]]), "s\n")
}
dir.create("results", showWarnings = FALSE)
write.csv(do.call(rbind, est), "results/replicates.csv", row.names = FALSE)
write.csv(do.call(rbind, fid), "results/fidelity.csv", row.names = FALSE)
