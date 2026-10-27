# fidelity and privacy of a copy s against d

tvd <- function(x, y) 0.5 * sum(abs(prop.table(table(x)) - prop.table(table(y))))

ecdf_dist <- function(x, y) {
  t <- sort(unique(c(x, y)))
  max(abs(ecdf(x)(t) - ecdf(y)(t)))
}

km_curve <- function(time, status) {
  f <- survival::survfit(survival::Surv(time, status) ~ 1)
  stepfun(f$time, c(1, f$surv))
}

# largest KM gap over five years, over arms;
# later the curves rest on a few patients
HORIZON <- 1826

km_dist <- function(s, d, time, status, horizon = HORIZON) {
  max(vapply(levels(d$rx), function(a) {
    i <- s$rx == a
    if (sum(i) == 0) return(1)
    j <- d$rx == a
    fs <- km_curve(s[[time]][i], num(s[[status]][i]))
    fo <- km_curve(d[[time]][j], num(d[[status]][j]))
    t <- sort(unique(c(0, s[[time]][i], d[[time]][j])))
    t <- t[t <= horizon]
    max(abs(fs(t) - fo(t)))
  }, numeric(1)))
}

# arm as two indicators, the rest as numbers
as_matrix <- function(d) {
  m <- sapply(setdiff(VARS, "rx"), function(v) num(d[[v]]))
  cbind(lev = as.numeric(d$rx == "Lev"), lev5fu = as.numeric(d$rx == "Lev+5FU"), m)
}

cor_diff <- function(s, d) {
  cs <- suppressWarnings(cor(as_matrix(s), method = "spearman"))
  co <- cor(as_matrix(d), method = "spearman")
  cs[is.na(cs)] <- 0  # a constant column has no correlation
  mean(abs(cs - co)[upper.tri(co)])
}

pmse <- function(s, d) {
  u <- suppressWarnings(synthpop::utility.gen(s, d, method = "logit", maxorder = 1,
                                              print.flag = FALSE))
  u$S_pMSE
}

exact_share <- function(s, d) {
  key <- function(x) do.call(paste, c(lapply(x, as.character), sep = "|"))
  mean(key(s) %in% key(d))
}

dcr_median <- function(s, d) {
  g <- as.matrix(cluster::daisy(rbind(s, d), metric = "gower"))
  n <- nrow(s)
  median(apply(g[seq_len(n), n + seq_len(nrow(d)), drop = FALSE], 1, min))
}

fidelity <- function(s, d) {
  c(S_pMSE = pmse(s, d),
    tvd = mean(vapply(CATEGORICAL, function(v) tvd(s[[v]], d[[v]]), numeric(1))),
    ks = mean(vapply(CONTINUOUS, function(v) ecdf_dist(s[[v]], d[[v]]), numeric(1))),
    km_rec = km_dist(s, d, "rec_time", "rec_status"),
    km_os = km_dist(s, d, "os_time", "os_status"),
    cor_diff = cor_diff(s, d),
    exact = exact_share(s, d),
    dcr = dcr_median(s, d))
}
