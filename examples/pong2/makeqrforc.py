from PIL import Image
from subprocess import Popen
import sys

if len(sys.argv) < 2:
  print "Please specify a string to encode"
  sys.exit(0)

pr = Popen(['qrencode', "-otemp.png", "-s 1", "-m 2", " ".join(sys.argv[1:])])
pr.wait()

im = Image.open("temp.png")

fw = file("qr.c", "w");

fw.write("int qrwidth = %d;\n" % im.size[0])
fw.write("int qrheight = %d;\n" % im.size[1])
fw.write("const char qr[] = {\n");

for i in range(im.size[1]):
  for j in range(im.size[0]):
    fw.write("0x%02x, " % im.getpixel((j, i)))
  fw.write("\n")

fw.seek(-3,2);
fw.write("\n};\n");
fw.close()

