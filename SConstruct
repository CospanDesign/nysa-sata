import os
import sys
import json
import SCons
import site

from string import Template

SITE_PATH = os.path.join(site.getuserbase(), "nysa")
PATHS_PATH = os.path.join(SITE_PATH, "paths.json")

verilog_builder = Builder ( action = 'iverilog -o$TARGET -c$SOURCE',
                            suffix = '.sim')
sim_builder = Builder     ( action = 'vvp $SOURCE', suffix='.vcd')
wave_builder = Builder    ( action = 'gtkwave design.vcd &')

env = Environment(ENV=os.environ,
                  BUILDERS={'verilog':verilog_builder,
                    'sim':sim_builder,
                    'wave':wave_builder})

env.Alias("sim", 'design.vcd')
env.Alias("wave", 'design.vcd', "gtkwave design.vcd &")
env.Alias("build", 'design.sim')


AlwaysBuild('design.sim')
AlwaysBuild('design.vcd')

def fix_verilog_paths():
  #Open the configuration file from the default location
  try:
    f = open(PATHS_PATH, "r")
    #print "file: %s" % f.read()
    paths_dict = json.load(f)
    f.close()
    #print "Opened up the configuration file"

  except IOError:
    print ("Error user has not set up configuration file run 'nysa-update'")

  #Open the user command file
  f = open('command_file.txt')
  template = Template(f.read())
  f.close()
  #print "Opened up the command file"

  #Apply the configuration directory
  buf = template.safe_substitute(
    NYSA=paths_dict["verilog"]["nysa-verilog"]["path"]
  )

  buf = buf.replace('/', os.path.sep)

  #Write the output file
  #print "Opened up the temp file"
  f = open('temp.txt', 'w')
  f.write(buf)
  f.close()
  #print "Wrote the temp file"


print "Fixing verilog Paths..."
fix_verilog_paths()
build_retval = env.verilog('design.sim', 'temp.txt')
env.sim('design.vcd', build_retval)

Default('design.sim')

Clean('design.sim', ['design.vcd', 'temp.txt'])


