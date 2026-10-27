# one row per patient from survival::colon

VARS <- c("rx", "sex", "age", "obstruct", "perfor", "adhere", "differ", "extent", "surg",
          "nodes", "node4", "rec_time", "rec_status", "os_time", "os_status")
CONTINUOUS <- c("age", "nodes", "rec_time", "os_time")
CATEGORICAL <- setdiff(VARS, CONTINUOUS)
LEVELS <- list(rx = c("Obs", "Lev", "Lev+5FU"), sex = 0:1, obstruct = 0:1, perfor = 0:1,
               adhere = 0:1, differ = 1:3, extent = 1:4, surg = 0:1, node4 = 0:1,
               rec_status = 0:1, os_status = 0:1)

typed <- function(d) {
  d <- as.data.frame(d)[, VARS]
  for (v in CATEGORICAL) d[[v]] <- factor(as.character(d[[v]]), levels = as.character(LEVELS[[v]]))
  for (v in CONTINUOUS) d[[v]] <- as.integer(round(as.numeric(d[[v]])))
  rownames(d) <- NULL
  d
}

load_colon <- function() {
  d <- survival::colon
  rec <- d[d$etype == 1, ]
  os <- d[d$etype == 2, ]
  stopifnot(identical(rec$id, os$id))
  w <- data.frame(os[, c("rx", "sex", "age", "obstruct", "perfor", "adhere", "differ", "extent",
                         "surg", "nodes", "node4")],
                  rec_time = rec$time, rec_status = rec$status,
                  os_time = os$time, os_status = os$status)
  typed(w[complete.cases(w), ])
}

read_syn <- function(path) typed(read.csv(path, stringsAsFactors = FALSE))
