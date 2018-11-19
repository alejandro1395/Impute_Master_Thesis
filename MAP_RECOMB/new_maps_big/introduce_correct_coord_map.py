#!/usr/bin/python3

import sys
import re
import fileinput

#DICTIONARY WITH COVERAGES

converted_read = True

if len(sys.argv) == 5:
    unmapped = sys.argv[1]
    converted = sys.argv[2]
    genetic_map = sys.argv[3]
    chr = sys.argv[4]
else:
    sys.exit("The usage should be ./convert_4Ner_to_cM.py \
    zip_4Ner_chr Ne out_cM_file")

Excluded = []
previous = 0

with open(unmapped, "r") as in_fh:
    for line in in_fh:
        line = line.rstrip()
        if not line.startswith("#"):
            chr_coord = int(line.split()[2])
            Excluded.append(chr_coord)


with open(genetic_map, "r") as in2_fh:
    with open(converted, "r") as in3_fh:
        for line1, line2 in zip(in2_fh, in3_fh):
            line1 = line1.rstrip()
            line2 = line2.rstrip()
            fields1 = line1.split()
            fields2 = line2.split()
            pos = int(fields2[2])
            if pos > previous:
                if (fields1[1] not in Excluded) and (fields2[0] == chr):
                    print("{}\t{}".format(fields2[2], fields1[2]))
                    previous = pos
                    continue
                else:
                    if fields1[0] in Excluded:
                        unmapped_read = True
                        while unmapped_read:
                            line1 = next(in2_fh)
                            fields1 = line1.rstrip().split()
                            if (fields1[1] not in Excluded) and (fields2[0] == chr):
                                print("{}\t{}".format(fields2[2], fields1[2]))
                                unmapped_read = False
                                previous = pos
                                break
                            elif (fields1[1] not in Excluded) and (fields2[0] != chr):
                                previous = pos
                                break
            else:
                next(in2_fh)
                next(in3_fh)
