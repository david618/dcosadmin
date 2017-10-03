import urllib
import json
import time
import sys


if __name__ == '__main__':

	agent=sys.argv[1]

	url = "http://" + agent + ":5051/monitor/statistics"


	executors = {}


	response = urllib.urlopen(url)

	data = json.loads(response.read())

	for itm in data:
		executor = {}
		id = itm["executor_id"]
		executor["name"] = itm["executor_name"]

		a = {}
		a["cpu_system"] = itm["statistics"]["cpus_system_time_secs"]
		a["cpu_user"] = itm["statistics"]["cpus_user_time_secs"]
		a["ts"] = itm["statistics"]["timestamp"]
		executor["a"] = a

		executors[id] = executor

	time.sleep(5)
	response = urllib.urlopen(url)

	data = json.loads(response.read())

    
	for itm in data:
		id = itm["executor_id"]

		b = {}
		b["cpu_system"] = itm["statistics"]["cpus_system_time_secs"]
		b["cpu_user"] = itm["statistics"]["cpus_user_time_secs"]
		b["ts"] = itm["statistics"]["timestamp"]


		executors[id]["b"] = b


	for id,itm in executors.items():
		cpus_total_usage = ((itm["b"]["cpu_system"]-itm["a"]["cpu_system"]) + \
                        (itm["b"]["cpu_user"]-itm["a"]["cpu_user"])) / \
                        (itm["b"]["ts"]-itm["a"]["ts"])
		print(str(id) + " : " + str(cpus_total_usage))


