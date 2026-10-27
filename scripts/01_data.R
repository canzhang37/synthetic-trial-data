# analysis data, reference findings, BN arcs
for (f in list.files("R", full.names = TRUE)) source(f)
dir.create("data", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)

d <- load_colon()
write.csv(d, "data/colon.csv", row.names = FALSE)
ref <- merge(FINDINGS, findings(d))
ref$hr <- exp(ref$est)
write.csv(ref, "results/reference.csv", row.names = FALSE)
print(ref, digits = 3)

net <- bn_structure(d)
arcs <- as.data.frame(bnlearn::arcs(net))
write.csv(arcs, "results/bn_arcs.csv", row.names = FALSE)
cat(nrow(d), "patients;", nrow(arcs), "arcs in the network; arcs at rx:\n")
print(arcs[arcs$from == "rx" | arcs$to == "rx", ])
