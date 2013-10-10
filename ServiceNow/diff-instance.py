#!/usr/bin/env python -u
"""
Based on retrieved & committed update sets, show the skew between one 
ServiceNow instance and another. Helps if your dev pipeline is FUBAR'ed by 
vortices at the bottom of a Waterfall SDLC. 

Also helps you ID update sets to push if you haven't grouped them. Potential
building block for automating update migration junk.

Important: may rely on glide.processor.json.row_limit being set to an amount
greater than the number of rows in your remote_update_set table.

This is for people who use a single update source and perhaps multiple
"branches." A saner way to do this is to just chain your update set 
sources, e.g.

    dev <- test <- staging <- prod

...or something similar. 

But even if you do, you'll need to know the order in which to apply them.

Example: 

$ diff-instance.py inst1 inst2

Might yield:

    Update Set 1 | 2013-10-09 17:37:05
    Update Set 3 | 2013-10-09 20:30:19
    Update Set 2 | 2013-10-09 20:35:28

...telling you that these three update sets:

    - are in inst1 but /not/ in inst2
    - need to be applied in the order 1, 2, 3
"""
import sys
import urllib2
import getpass
import base64
import json

USERNAME = ''

def main():
        
    instances = [ SNowInstance(i) for i in load() ]
    updatesets = [ i.get_updatesets() for i in instances ]

    # for each update in first, if it's missing in second, add it to missing[]
    missing = []
    for name in updatesets[0]:
        if name not in updatesets[1]:
            n = updatesets[0][name]['name']
            c = updatesets[0][name]['commit_date']
            u = (n,c)
            missing.append(u)

    # print missing sets in sorted order by commit date (second field)
    missing = sorted(missing, key=lambda x: x[1]) 
    for u in missing:
        print u[0] + ' | ' + u[1]

# parse args
def load():
    if len(sys.argv) < 3:
        sys.stderr.write('\nusage: ' + sys.argv[0] + ' inst1 inst2\n\n')
        sys.exit()
    else:
        return [sys.argv[1], sys.argv[2]]


class SNowInstance:
    name = ''
    creds = ''
    baseurl = ''

    def get_updatesets(self):
        qstring = '' \
                + '/sys_remote_update_set_list.do?' \
                + 'sysparm_query=state%3Dcommitted' \
                + '&JSON' \
                + ''
        updatesets = {}

        data = json.loads(self.query(qstring).read())
        update_sets = data['records']
        for updateset in update_sets:
            s = updateset['origin_sys_id']
            n = updateset['name']
            c = updateset['commit_date']
            updatesets[n] = {'origin_sys_id': s, \
                             'name': n, \
                             'commit_date': c, \
                              }
        return updatesets

    def getcreds(self):
        if USERNAME == '':
            sys.stdout.write(self.name + ' Username: ')
            user = raw_input()
        else:
            user = USERNAME
        pw = getpass.getpass()
        return base64.encodestring('%s:%s' % (user, pw)).replace('\n', '')
	       
    def query(self, q):
        target = self.baseurl + '/' + q
        request = urllib2.Request(target)
        request.add_header("Authorization", "Basic %s" % self.creds)
        return urllib2.urlopen(request)

    def __init__(self,n):
        self.name = n
        self.creds = self.getcreds()
        self.baseurl = 'https://' + n + '.service-now.com'

if __name__ == '__main__':
    main()
