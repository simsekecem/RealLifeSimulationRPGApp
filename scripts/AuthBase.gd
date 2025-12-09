extends Node

const WORKER_URL = "https://life-sim-worker.life-simulation.workers.dev"

func send_request(http: HTTPRequest, endpoint: String, body: Dictionary) -> void:
	var url = WORKER_URL + endpoint
	var headers = [
		"Content-Type: application/json"
	]
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
