# encoding: utf-8
import re
import os
import subprocess
if __name__ == "__main__":
    p = subprocess.Popen('docker images', shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    for line in p.stdout.readlines():

        # The regular expression here is to match the image name starting with hub.bk
        # The actual use of the need to adjust their own
        m = re.match(r'(^hub.bk[^\s]*\s*)\s([^\s]*\s)', line)
        if not m:
            continue
        # image name 
        iname = m.group(1).strip()
        # tag
        itag = m.group(2).strip()
        # tar name
        if iname.find('/'):
            tarname = iname.split('/')[0] + '_' + iname.split('/')[-1]  + '_' + itag + '.tar'
        else:
            tarname = iname + '_' + itag + '.tar'
        print tarname
        ifull = iname + ':' + itag
        #save
        cmd = 'docker save -o ' + tarname + ' ' + ifull
        print os.system(cmd)
    retval = p.wait()