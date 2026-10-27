# estimates by method; KM curves of one copy
suppressPackageStartupMessages(library(ggplot2))
for (f in list.files("R", full.names = TRUE)) source(f)
dir.create("figures", showWarnings = FALSE)
methods <- c(bootstrap = "Bootstrap", cart = "CART", bn = "Bayesian network", ctgan = "CTGAN")
cols <- c(Bootstrap = "#2a78d6", CART = "#eb6834", `Bayesian network` = "#1baf7a", CTGAN = "#eda100")
ink <- "#52514e"

ref <- read.csv("results/reference.csv")
est <- read.csv("results/replicates.csv")
est$method <- factor(methods[est$method], rev(methods))
est$label <- factor(ref$label[match(est$finding, ref$finding)], ref$label)
ref$label <- factor(ref$label, ref$label)

p <- ggplot(est, aes(exp(est), method)) +
  geom_rect(data = ref, aes(xmin = exp(lo), xmax = exp(hi), ymin = -Inf, ymax = Inf),
            inherit.aes = FALSE, fill = "#e9e8e4") +
  geom_vline(data = ref, aes(xintercept = exp(est)), colour = ink, linewidth = 0.5) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "#a3a29c", linewidth = 0.4) +
  geom_jitter(aes(colour = method), height = 0.18, width = 0, size = 1, alpha = 0.55) +
  stat_summary(fun = median, geom = "point", shape = 21, size = 2.6, fill = "white",
               colour = "#0b0b0b", stroke = 0.6) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_x_log10() +
  facet_wrap(~label, scales = "free_x", ncol = 2) +
  labs(x = "hazard ratio (log scale); grey band = original estimate and 95% interval; circle = median",
       y = NULL) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        strip.text = element_text(hjust = 0, face = "bold"), axis.title.x = element_text(colour = ink, size = 8.5),
        plot.background = element_rect(fill = "#fcfcfb", colour = NA))
ggsave("figures/estimates.png", p, width = 8, height = 5, dpi = 150)

d <- read_syn("data/colon.csv")
km_df <- function(x, src) {
  do.call(rbind, lapply(levels(x$rx), function(a) {
    i <- x$rx == a
    f <- survival::survfit(survival::Surv(x$os_time[i], num(x$os_status[i])) ~ 1)
    data.frame(arm = a, src = src, t = c(0, f$time) / 365.25, s = c(1, f$surv))
  }))
}
km <- do.call(rbind, lapply(names(methods), function(m) {
  s <- repair(read_syn(file.path("data", "synthetic", m, "rep_001.csv")))
  rbind(cbind(method = methods[[m]], km_df(d, "original")),
        cbind(method = methods[[m]], km_df(s, "synthetic copy 1")))
}))
km$method <- factor(km$method, methods)
km$arm <- factor(km$arm, c("Obs", "Lev", "Lev+5FU"))
q <- ggplot(km, aes(t, s, colour = arm, linetype = src)) +
  geom_step(linewidth = 0.6) +
  scale_colour_manual(values = c(Obs = "#2a78d6", Lev = "#eb6834", `Lev+5FU` = "#1baf7a"),
                      name = NULL) +
  scale_linetype_manual(values = c(original = "solid", `synthetic copy 1` = "22"), name = NULL) +
  facet_wrap(~method, ncol = 2) +
  coord_cartesian(xlim = c(0, 8), ylim = c(0.3, 1)) +
  labs(x = "years from registration", y = "overall survival") +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "top",
        strip.text = element_text(hjust = 0, face = "bold"),
        plot.background = element_rect(fill = "#fcfcfb", colour = NA))
ggsave("figures/km_copies.png", q, width = 8, height = 5.6, dpi = 150)
