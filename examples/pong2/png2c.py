from PIL import Image
import sys
import os

if len(sys.argv) < 2:
  print "Please specify a file to convert"
  sys.exit(0)

im = Image.open(sys.argv[1])

filename = os.path.splitext(sys.argv[1])[0] + ".c"

fw = file(filename, "w");

fw.write("int imwidth = %d;\n" % im.size[0])
fw.write("int imheight = %d;\n" % im.size[1])
fw.write("const char im[] = {\n");

for i in range(im.size[1]):
  for j in range(im.size[0]):
    fw.write("0x%02x, " % im.getpixel((j, i)))
  fw.write("\n")

fw.seek(-3,2);
fw.write("\n};\n");
fw.close()

