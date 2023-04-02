#!/usr/bin/env python

#Originally made by andersonmendess and some more stuff added by peaktogoo.

import os, json, sys

paths = ['builds','devices.json','incremental/builds']

indents = 3

def main():
	if len(sys.argv) > 1:
		if sys.argv[1] == "example":
			print("Not formatting example.json. QUITTING THE SCRIPT! [This is normal behavior]]")
			exit()
		else:
			formatter('builds/'+sys.argv[1]+".json")
			exit()

	for path in paths:
		if os.path.isdir(path):
			for file in os.listdir(path):
				pathfile = f"{path}/{file}"
				if "builds/example.json" == pathfile:
					print("Not formatting example.json. [This is normal behavior]")
				else:
					formatter(path+'/'+file)
		elif os.path.isfile(path):
  			formatter(path)


def formatter(path):
	if not path.endswith('.json'):
		return
	try:
		data = json.loads(open(path).read())
		outfile = open(path, 'w')
		json.dump(data, outfile, indent=indents, ensure_ascii=False, sort_keys=True)
		print(f"{path}, JSON Formatted!")
	except Exception as e:
		print(f"{path}, JSON Formatting errored with the following exception!\n{e}")

if __name__== "__main__":
  main()
