# bootstrap, CART and the Bayesian network

gen_bootstrap <- function(d, seed) {
  set.seed(seed)
  typed(d[sample.int(nrow(d), nrow(d), replace = TRUE), ])
}

gen_cart <- function(d, seed) {
  s <- synthpop::syn(d, method = "cart", visit.sequence = VARS, seed = seed, print.flag = FALSE)
  typed(s$syn)
}

# 0-1, 2, 3, 4, 5-8, 9 or more
NODE_BREAKS <- c(-Inf, 1, 2, 3, 4, 8, Inf)

bn_breaks <- function(d) {
  list(age = unique(quantile(d$age, seq(0, 1, 0.2), names = FALSE)),
       nodes = NODE_BREAKS,
       rec_time = unique(quantile(d$rec_time, seq(0, 1, 0.1), names = FALSE)),
       os_time = unique(quantile(d$os_time, seq(0, 1, 0.1), names = FALSE)))
}

discretize <- function(d, br) {
  for (v in names(br)) d[[v]] <- cut(d[[v]], br[[v]], include.lowest = TRUE)
  d
}

gen_bn <- function(d, seed) {
  br <- bn_breaks(d)
  dd <- discretize(d, br)
  fit <- bnlearn::bn.fit(bnlearn::hc(dd), dd, method = "bayes", iss = 1)
  set.seed(seed)
  s <- bnlearn::rbn(fit, n = nrow(d))[, VARS]
  for (v in c("age", "nodes")) {
    pool <- split(d[[v]], dd[[v]])
    s[[v]] <- vapply(as.character(s[[v]]), function(b) {
      p <- pool[[b]]
      p[sample.int(length(p), 1)]
    }, numeric(1), USE.NAMES = FALSE)
  }
  for (v in c("rec_time", "os_time")) {
    i <- as.integer(s[[v]])
    s[[v]] <- round(runif(nrow(s), br[[v]][i], br[[v]][i + 1]))
  }
  typed(s)
}

bn_structure <- function(d) bnlearn::hc(discretize(d, bn_breaks(d)))

# structural rules, counted before repair
violations <- function(s) {
  c(V1 = mean(s$rec_time > s$os_time),
    V2 = mean(s$rec_status == "0" & s$rec_time != s$os_time))
}

repair <- function(s) {
  s$rec_time <- pmin(s$rec_time, s$os_time)
  no_rec <- s$rec_status == "0"
  s$rec_time[no_rec] <- s$os_time[no_rec]
  s
}
