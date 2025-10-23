extends Node

const SUPABASE_URL = "https://rzsndtstonztfuayodmg.supabase.co"
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ6c25kdHN0b256dGZ1YXlvZG1nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAyOTg4OTQsImV4cCI6MjA3NTg3NDg5NH0.UPDS44mZl-YP0UNGqnpPzIedyphNptgnXehax5tUi50"

func send_request(http: HTTPRequest, url: String, body: Dictionary) -> void:
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_KEY
	]
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
