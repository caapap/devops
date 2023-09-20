# function:
# docker load -i <images-file-tar>
import  os
images = os.listdir(os.getcwd())
for imagename in images:
    if imagename.endswith('.tar'):
        print(imagename)
        os.system('docker load -i %s'%imagename)