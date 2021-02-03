import sys
import re
import camelot

tables = camelot.read_pdf(sys.argv[1])

def cleanupStr(s):
    s = re.sub(r'\s', ' ', s)
    s = re.sub(r'※\d*', '', s)
    s = re.sub(r'\s{2,}', ' ', s)
    return s.strip()

for tbl in tables:
    for i in tbl.df.index:
        print('|'.join([cleanupStr(s) for s in tbl.df.loc[i]]))
