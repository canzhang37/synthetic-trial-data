# Rscript scripts/02_generate.R [methods] [reps]
# CTGAN copies come from python/
for (f in list.files("R", full.names = TRUE)) source(f)
args <- commandArgs(trailingOnly = TRUE)
methods <- if (length(args) >= 1) strsplit(args[1], ",")[[1]] else c("bootstrap", "cart", "bn")
reps <- if (length(args) >= 2) as.integer(args[2]) else 100
SEED0 <- 2027

d <- read_syn("data/colon.csv")
gen <- list(bootstrap = gen_bootstrap, cart = gen_cart, bn = gen_bn)
for (m in methods) {
  out <- file.path("data", "synthetic", m)
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  t <- system.time(for (r in seq_len(reps)) {
    s <- gen[[m]](d, SEED0 + r)
    write.csv(s, file.path(out, sprintf("rep_%03d.csv", r)), row.names = FALSE)
  })
  cat(m, ":", reps, "data sets in", round(t[["elapsed"]]), "s\n")
}
