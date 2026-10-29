#!/usr/bin/env python3
import gzip
import re
from collections import defaultdict

infile = "/shared/projects/delissea_genome/finalresults/ena_flatfiles/ena_flatfile.embl.gz"
outfile = "/shared/projects/delissea_genome/finalresults/ena_flatfiles/ena_flatfile_dedup.embl.gz"

# regex to identify a feature header line
feature_re = re.compile(r"^FT\s+(\S+)\s+(\S+)")

# store unique features by (type, location)
seen = defaultdict(list)
output_lines = []
inside_feature = False
current_feature = []

def flush_feature():
    """Store a completed feature if it's not duplicate."""
    if not current_feature:
        return
    header = current_feature[0]
    m = feature_re.match(header)
    if not m:
        output_lines.extend(current_feature)
        return
    ftype, floc = m.groups()
    key = (ftype, floc)
    if key not in seen:
        seen[key] = ["".join(current_feature)]
        output_lines.extend(current_feature)
    # duplicates are skipped entirely

with gzip.open(infile, "rt") as fh:
    for line in fh:
        if feature_re.match(line):
            flush_feature()
            current_feature = [line]
            inside_feature = True
        elif inside_feature and line.startswith("FT"):
            current_feature.append(line)
        else:
            flush_feature()
            current_feature = []
            inside_feature = False
            output_lines.append(line)
    flush_feature()

with gzip.open(outfile, "wt") as out:
    out.writelines(output_lines)

print(f"✅ Duplicates removed. Clean file written to: {outfile}")
