package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"net/http"
	"encoding/json"
	"io/ioutil"
	"time"
	"strings"
	//	"reflect"
)

type service struct {
	Targets  []string          `json:"targets"`
	Labels map[string]string   `json:"labels"`
}

const URL_FRAMEWORKS string = "http://leader.mesos:5050/frameworks"
const XD_PORT_NAME string = "13423"
const KAFKA_PORT_NAME string = "jmxexporter"
const METRICS_PORT_NAME string = "metrics"
const PROMETHEUS_PORT_NAME string = "prometheus"
const POOL_PORT_NAME string = "monitor"

func getService(fwName string, taskJSON map[string]interface{}, taskPort map[string]interface{}) *service {
	metricsPort := taskPort["number"]
	taskStatuses := taskJSON["statuses"].([]interface{})
	endpointPath := "/metrics"

	var taskIP string
	if taskStatuses != nil {
		for status := range taskStatuses {
			if taskStatuses[status].(map[string]interface{})["state"] == "TASK_RUNNING" {
				taskIP = taskStatuses[status].(map[string]interface{})["container_status"].(
				map[string]interface{})["network_infos"].([]interface{})[0].(map[string]interface{})[
					"ip_addresses"].([]interface{})[0].(map[string]interface{})["ip_address"].(string)
			}
		}
	}

	taskHost := fmt.Sprintf("%s%s%d", taskIP, ":", int(metricsPort.(float64)))

	var s *service
	s = &service{
		Targets: []string{taskHost},
		Labels: map[string]string{"name": taskJSON["name"].(string), "framework": fwName,
			"task_id": taskJSON["name"].(string), "framework_id": taskJSON["framework_id"].(string),
			"slave_id": taskJSON["framework_id"].(string)}}

	if taskPort["labels"] != nil {
		for label := range taskPort["labels"].(map[string]interface{})["labels"].([]interface{}) {
			if strings.ToLower(taskPort["labels"].(map[string]interface{})["labels"].([]interface{})[label].(map[string]interface{})["key"].(string)) == "metrics_path" {
				endpointPath = taskPort["labels"].(map[string]interface{})["labels"].([]interface{})[label].(map[string]interface{})["value"].(string)
				s = &service{
					Targets: []string{taskHost},
					Labels: map[string]string{"name": taskJSON["name"].(string), "framework": fwName,
						"task_id": taskJSON["name"].(string), "framework_id": taskJSON["framework_id"].(string),
						"slave_id": taskJSON["framework_id"].(string), "__metrics_path__": endpointPath}}
			}
		}
	}

	return s
}

func getFrameworkData(framework map[string]interface{}, portname string) []*service {

	fwServices := []*service{}

	frameworkName := framework["name"].(string)
	frameworkTasks := framework["tasks"].([]interface{})
	if frameworkTasks != nil {
		for task := range frameworkTasks {
			taskJSON := frameworkTasks[task].(map[string]interface{})
			taskDiscovery := taskJSON["discovery"]
			if taskDiscovery != nil {
				if taskDiscovery.(map[string]interface{})["ports"] != nil {
					taskPorts := taskDiscovery.(map[string]interface{})["ports"].(map[string]interface{})["ports"]
					if taskPorts != nil {
						for port := range taskPorts.([]interface{}) {
							taskPortName := taskPorts.([]interface{})[port].(map[string]interface{})["name"]

							switch taskPortName {
							case portname, XD_PORT_NAME, KAFKA_PORT_NAME, METRICS_PORT_NAME, PROMETHEUS_PORT_NAME, POOL_PORT_NAME:
								taskPort := taskPorts.([]interface{})[port].(map[string]interface{})
								var s *service
								s = getService(frameworkName, taskJSON, taskPort)
								fwServices = append(fwServices, s)
							}
						}
					}
				}
			}
		}
	}

	return fwServices
}

func generate(outfile string, portname string) {
	frameworksResp, err := http.Get(URL_FRAMEWORKS)
	if err != nil {
		log.Println(fmt.Sprintf("Error: %s", err))
		return
	} else {

		frameworksBytes, err2 := ioutil.ReadAll(frameworksResp.Body)
		if err2 != nil {
			log.Println(fmt.Sprintf("Error: %s", err2))
			return
		}

		var frameworksDecoded map[string]interface{}
		if err := json.Unmarshal(frameworksBytes, &frameworksDecoded); err != nil {
			log.Println(fmt.Sprintf("Error: %s", err))
			return
		}

		frameworks := frameworksDecoded["frameworks"].([]interface{})

		services := []*service{}
		var ser []*service
		for fw := range frameworks {
			ser = getFrameworkData(frameworks[fw].(map[string]interface{}), portname)
			if ser != nil {
				services = append(services, ser...)
			}
		}

		var servicesFile []byte
		servicesFile, _ = json.Marshal(services)
		file, err := ioutil.TempFile("", "servicesFile")
		if err != nil {
			log.Println(err)
			return
		}
		if _, err = file.Write([]byte(servicesFile)); err != nil {
			log.Println(err)
			return
		}

		if err = file.Close(); err != nil {
			log.Println(err)
			return
		}

		if err = os.Chmod(file.Name(), 0644); err != nil {
			log.Println(err)
			return
		}

		if err = os.Rename(file.Name(), outfile); err != nil {
			log.Println(err)
			return
		}

	}
}


func main() {
	outfile := flag.String("out", "", "Path to JSON file to write")
	portname := flag.String("portname", "", "Name of the metrics port")
	loop := flag.Bool("loop", false, "Loop forever")
	looptime := flag.Int("time", 300, "Time to wait between hostname resolution refresh cycles")
	flag.Parse()

	if *outfile == "" {
		flag.PrintDefaults()
		os.Exit(1)
	}
	if *loop {
		for {
			generate(*outfile, *portname)
			time.Sleep(time.Duration(*looptime) * time.Second)
		}
	} else {
		generate(*outfile, *portname)
	}

}