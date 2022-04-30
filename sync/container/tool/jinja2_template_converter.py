#!/usr/bin/python3
# -*- coding: utf-8 -*-
import sys, os
from jinja2 import Template, Environment, FileSystemLoader

def main(args):
  # check arguments
  if len(args) < 4 or ((len(args) - 2) % 2) != 0:
    usage(os.path.basename(args[0]))
    return
  
  # get paramaters from arguments
  src_path = os.path.abspath(args[1])
  key_value = {}
  for i in range(2, len(args), 2):
    key_value[args[i]] = args[i + 1]
  
  # change current directory to root
  # *to deal with the pattern that causes jinja2.exceptions.TemplateNotFound
  crnt_path = os.getcwd()
  os.chdir('/')
  
  # convert template file and save converted file
  result_str = convert_template(src_path, **key_value)
  print(result_str)
  
  # change current directory to script startup path
  os.chdir(crnt_path)
  return

def convert_template(template_path, **key_value):
  # load template file
  env = Environment(loader=FileSystemLoader('.'))
  template = env.get_template(template_path)
  
  # get string after template file conversion
  render = template.render(key_value)
  return str(render + "\n")

def usage(script):
  # display usage
  usage = "Usage: " + script + " [SRC-FILE] [KEYWORD1] [VALUE1] [KEYWORD1] [VALUE2]..."
  print(usage)
  return

main(sys.argv)
exit()
