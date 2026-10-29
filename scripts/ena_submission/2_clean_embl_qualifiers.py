#!/usr/bin/env python3
import gzip
import re

infile = "/shared/projects/delissea_genome/finalresults/ena_flatfiles/ena_flatfile_filtered.embl.gz"
outfile = "/shared/projects/delissea_genome/finalresults/ena_flatfiles/ena_flatfile_cleaned.embl.gz"
logfile = "ena_flatfile_removed_qualifiers.txt"

feature_start = re.compile(r"^FT\s+(\S+)\s+")
qualifier_re = re.compile(r'FT\s+/(\S+)=')  # match qualifier key

invalid_for_non_cds = {"codon_start", "transl_table"}
seen_locus_tag = False
removed_log = []

current_feature = []
output_lines = []
feature_type = None

def flush_feature():
    global seen_locus_tag
    if not current_feature:
        return
    clean_lines = []
    locus_tag_seen = False
    for line in current_feature:
        qmatch = qualifier_re.match(line)
        if qmatch:
            q = qmatch.group(1)
            # remove invalid qualifiers from non-CDS
            if feature_type != "CDS" and q in invalid_for_non_cds:
                removed_log.append(f"{feature_type}: removed {q}")
                continue
            # ensure only one locus_tag
            if q == "locus_tag":
                if locus_tag_seen:
                    removed_log.append(f"{feature_type}: removed duplicate locus_tag")
                    continue
                locus_tag_seen = True
        clean_lines.append(line)
    output_lines.extend(clean_lines)

with gzip.open(infile, "rt") as fh:
    for line in fh:
        m = feature_start.match(line)
        if m:
            # flush previous feature
            flush_feature()
            # start new one
            current_feature = [line]
            feature_type = m.group(1)
            seen_locus_tag = False
        elif line.startswith("FT"):
            current_feature.append(line)
        else:
            flush_feature()
            current_feature = []
            feature_type = None
            output_lines.append(line)
flush_feature()

with gzip.open(outfile, "wt") as out:
    out.writelines(output_lines)

with open(logfile, "w") as log:
    log.write("\n".join(removed_log))

print(f"Cleaned EMBL written to {outfile}")
print(f"Log of removed qualifiers: {logfile}")
