require "json"
require "csv"

directory = ARGV.fetch(0)
read_json = ->(name) { JSON.parse(File.read(File.join(directory, name)).sub(/^\uFEFF/, "")) }
run = read_json.call("run.json")
summary = read_json.call("summary.json")
expected = run.fetch("requests")
raise "Unexpected request count" unless summary.dig("metrics", "http_reqs", "values", "count") == expected
summary.fetch("metrics").each do |name, metric|
  (metric["thresholds"] || {}).each do |threshold, result|
    raise "Failed #{name}: #{threshold}" unless result.fetch("ok")
  end
end

responses = 0
CSV.open(File.join(directory, "requests.csv"), "w") do |csv|
  csv << %w[timestamp endpoint deployment instance status response_time_ms]
  File.foreach(File.join(directory, "samples.json")) do |line|
    sample = JSON.parse(line)
    next unless sample["type"] == "Point" && sample["metric"] == "response_time_by_instance"
    data = sample.fetch("data")
    tags = data.fetch("tags")
    csv << [ data["time"], tags["endpoint"], tags["deployment"], tags["instance"], tags["status"], data["value"] ]
    responses += 1
  end
end
raise "Missing per-request samples" unless responses == expected

if run["kubernetesContext"].to_s.empty?
  process_headers = %w[timestamp container name pid start_ticks command cpu_percent cpu_interval_seconds rss_bytes virtual_bytes threads]
  measured = 0
  CSV.open(File.join(directory, "processes.csv"), "w") do |csv|
    csv << process_headers
    File.foreach(File.join(directory, "processes.jsonl")) do |line|
      row = JSON.parse(line)
      csv << row.values_at(*process_headers)
      measured += 1 unless row["cpu_percent"].nil?
    end
  end
  raise "No process CPU intervals collected" if measured.zero?
  CSV.open(File.join(directory, "containers.csv"), "w") do |csv|
    csv << %w[timestamp container name cpu_percent memory_usage memory_percent threads pids]
    File.foreach(File.join(directory, "containers.jsonl")) do |line|
      row = JSON.parse(line)
      stats = row.fetch("stats")
      csv << [ row["timestamp"], stats["ID"], stats["Name"], stats["CPUPerc"].delete_suffix("%"), stats["MemUsage"], stats["MemPerc"].delete_suffix("%"), row["threads"], stats["PIDs"] ]
    end
  end
end
puts "Validated #{responses} requests; exported CSV files."
