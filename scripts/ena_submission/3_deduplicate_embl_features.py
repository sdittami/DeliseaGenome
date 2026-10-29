#!/usr/bin/env python3
import gzip
import re
from collections import defaultdict

infile = "/shared/projects/delissea_genome/finalresults/ena_flatfiles/ena_flatfile_cleaned.embl.gz"
outfile = "/shared/projects/delissea_genome/finalresults/ena_flatfiles/ena_flatfile_dedup2.embl.gz"
logfile = "ena_flatfile_dedup2.log"

feature_start = re.compile(r"^FT\s+(\S+)\s+(.+)")
qualifier_re = re.compile(r"FT\s+/(\S+)=([^\n]*)")

def serialize_feature(ftype, loc):
    """Unique key for features of same type+location"""
    return f"{ftype}:{loc.strip()}"

# store all features in memory
features = defaultdict(list)
current_feature = []
current_key = None
seq_lines = []

with gzip.open(infile, "rt") as fh:
    for line in fh:
        if line.startswith("FT"):
            m = feature_start.match(line)
            if m:
                # New feature
                if current_feature:
                    features[current_key].append(current_feature)
                ftype, loc = m.groups()
                current_feature = [line]
                current_key = serialize_feature(ftype, loc)
            else:
                current_feature.append(line)
        else:
            if current_feature:
                features[current_key].append(current_feature)
                current_feature = []
                current_key = None
            seq_lines.append(line)

# merge duplicates
merged_features = []
log = []

for key, feats in features.items():
    if len(feats) == 1:
        merged_features.extend(feats[0])
        continue

    # merge qualifiers of duplicates
    ftype, loc = key.split(":", 1)
    seen_qualifiers = {}
    merged_block = [f"FT   {ftype}             {loc}\n"]
    for f in feats:
        for line in f[1:]:  # skip first line
            q = qualifier_re.match(line)
            if q:
                name, val = q.groups()
                if name == "note":
                    # concatenate notes
                    if name in seen_qualifiers:
                        seen_qualifiers[name] += "; " + val.strip()
                    else:
                        seen_qualifiers[name] = val.strip()
                elif name not in seen_qualifiers:
                    seen_qualifiers[name] = val.strip()
            else:
                merged_block.append(line)
    # now add unique qualifiers
    for q, v in seen_qualifiers.items():
        merged_block.append(f"FT                   /{q}={v}\n")
    merged_features.extend(merged_block)
    log.append(f"Merged {len(feats)} duplicates for {key}")

# write output
with gzip.open(outfile, "wt") as out:
    for f in merged_features:
        out.write(f)
    for l in seq_lines:
        out.write(l)

with open(logfile, "w") as lf:
    lf.write("\n".join(log))

print(f"✅ Deduplicated EMBL written to {outfile}")
print(f"🧾 Log written to {logfile}")
