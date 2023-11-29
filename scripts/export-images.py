# encoding: utf-8

import re
import os
import subprocess

if __name__ == "__main__":
    p = subprocess.Popen('docker images', shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    for line in p.stdout.readlines():


        m = re.match('('+ regex_pattern + r'[^\s]*\s*)\s([^\s]*\s)', line)
        # 这一行正则匹配表达式，用来匹配含执行参数前缀的镜像文件
        # 执行方法：python export-images.py <images-url-*>

        # m = re.match(r'(^docker.io[^\s]*\s*)\s([^\s]*\s)', line)

        if not m:
            continue

        # 镜像名
        iname = m.group(1).strip()
        # tag
        itag = m.group(2).strip()
        # tar包的名字
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
