local config = {
    total_requests = 100000,
    methods = {
        post = { weight = 0.4, path = "/create/" },
        get = { weight = 0.4, path = "/" },
        put = { weight = 0.1, path = "/{id}/update/" },
        delete = { weight = 0.1, path = "/{id}/delete/" }
    }
}

local first_names = {"Emma", "Liam", "Olivia", "Noah", "Ava", "Oliver", "Isabella", "Lucas", "Sophia", "Mason"}
local last_names = {"Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez"}
local domains = {"gmail.com", "yahoo.com", "hotmail.com", "outlook.com", "example.com"}

local counter = 0
local requests_completed = 0
local start_time = 0
local stats = { post = { success = 0, failed = 0 }, get = { success = 0, failed = 0 }, put = { success = 0, failed = 0 }, delete = { success = 0, failed = 0 } }

local function generate_user_data()
    counter = counter + 1
    local first = first_names[math.random(#first_names)]
    local last = last_names[math.random(#last_names)]
    local domain = domains[math.random(#domains)]
    local email = string.format("%s.%s.%d@%s", string.lower(first), string.lower(last), counter, domain)
    return string.format('{"name":"%s %s","email":"%s"}', first, last, email)
end

local function choose_method()
    local r = math.random()
    local cumulative = 0
    for method, data in pairs(config.methods) do
        cumulative = cumulative + data.weight
        if r <= cumulative then
            return method, data.path
        end
    end
    return "get", config.methods.get.path
end

function init(args)
    math.randomseed(os.time())
    start_time = os.time()
    print(string.format("\nStarting benchmark with %d total requests...\n", config.total_requests))
end

function request()
    if requests_completed >= config.total_requests then
        wrk.thread:stop()
        return
    end
    
    requests_completed = requests_completed + 1
    local method, path = choose_method()
    
    local headers = { ["Content-Type"] = "application/json", ["X-Request-ID"] = string.format("%d-%d", os.time(), requests_completed) }
    
    if method == "post" then
        local payload = generate_user_data()
        headers["Content-Length"] = #payload
        return wrk.format("POST", path, headers, payload)
    elseif method == "put" then
        local user_id = math.random(1, 100)
        local payload = generate_user_data()
        headers["Content-Length"] = #payload
        path = string.gsub(path, "{id}", user_id)
        return wrk.format("PUT", path, headers, payload)
    elseif method == "delete" then
        local user_id = math.random(1, 100)
        path = string.gsub(path, "{id}", user_id)
        return wrk.format("DELETE", path, headers)
    else
        return wrk.format("GET", path, headers)
    end
end

function response(status, headers, body)
    local success_codes = {[200] = true, [201] = true}
    
    if status >= 200 and status < 300 then
        if wrk.method == "POST" then
            stats.post.success = stats.post.success + 1
        elseif wrk.method == "GET" then
            stats.get.success = stats.get.success + 1
        elseif wrk.method == "PUT" then
            stats.put.success = stats.put.success + 1
        elseif wrk.method == "DELETE" then
            stats.delete.success = stats.delete.success + 1
        end
    else
        if wrk.method == "POST" then
            stats.post.failed = stats.post.failed + 1
        elseif wrk.method == "GET" then
            stats.get.failed = stats.get.failed + 1
        elseif wrk.method == "PUT" then
            stats.put.failed = stats.put.failed + 1
        elseif wrk.method == "DELETE" then
            stats.delete.failed = stats.delete.failed + 1
        end
    end
end

function done(summary, latency, requests)
    local duration = os.time() - start_time
    
    print("\n====== Benchmark Results ======")
    print(string.format("Duration: %d seconds", duration))
    print(string.format("Total Requests: %d", requests_completed))
    print(string.format("Requests/sec: %.2f", requests_completed/duration))
    
    print("\nLatency:")
    print(string.format("  Mean: %.2fms", latency.mean/1000))
    print(string.format("  Max: %.2fms", latency.max/1000))
    print(string.format("  50th percentile: %.2fms", latency:percentile(50)/1000))
    print(string.format("  90th percentile: %.2fms", latency:percentile(90)/1000))
    print(string.format("  99th percentile: %.2fms", latency:percentile(99)/1000))
    
    print("\nRequest Statistics:")
    print("  POST:")
    print(string.format("    Success: %d", stats.post.success))
    print(string.format("    Failed: %d", stats.post.failed))
    print("  GET:")
    print(string.format("    Success: %d", stats.get.success))
    print(string.format("    Failed: %d", stats.get.failed))
    print("  PUT:")
    print(string.format("    Success: %d", stats.put.success))
    print(string.format("    Failed: %d", stats.put.failed))
    print("  DELETE:")
    print(string.format("    Success: %d", stats.delete.success))
    print(string.format("    Failed: %d", stats.delete.failed))
    print("============================\n")
end
