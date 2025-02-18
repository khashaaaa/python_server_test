math.randomseed(os.time())

local names = {
    "John Smith", "Emma Johnson", "Michael Brown", "Sarah Davis", "David Wilson",
    "Lisa Anderson", "James Taylor", "Emily White", "Robert Martin", "Jessica Lee",
    "William Clark", "Jennifer Hall", "Thomas Wright", "Elizabeth Green", "Daniel King",
    "Maria Garcia", "Joseph Miller", "Susan Moore", "Richard Lewis", "Laura Walker"
}

local domains = {"gmail.com", "yahoo.com", "hotmail.com", "example.com", "mail.com"}

local counter = 0

local function random_user()
    counter = counter + 1
    local name = names[math.random(1, #names)]
    local email = string.format("user%d@%s", counter, domains[math.random(1, #domains)])
    return string.format('{"name":"%s","email":"%s"}', name, email)
end

local function random_email()
    counter = counter + 1
    local email = string.format("updated%d@%s", counter, domains[math.random(1, #domains)])
    return string.format('{"email":"%s"}', email)
end

function setup(thread)
    thread:set("counter", 0)
    thread:set("id", 1)
end

function request()
    local thread_counter = wrk.thread:get("counter") or 0
    thread_counter = thread_counter + 1
    wrk.thread:set("counter", thread_counter)
    
    local choice = thread_counter % 5
    
    if choice == 0 then
        return wrk.format("GET", "/")
        
    elseif choice == 1 then
        wrk.headers["Content-Type"] = "application/json"
        return wrk.format("POST", "/create/", nil, random_user())
        
    elseif choice == 2 then
        local id = wrk.thread:get("id")
        wrk.headers["Content-Type"] = "application/json"
        return wrk.format("PUT", string.format("/%d/update/", id), nil, random_email())
        
    elseif choice == 3 then
        local id = wrk.thread:get("id")
        return wrk.format("DELETE", string.format("/%d/delete/", id))
        
    else
        return wrk.format("GET", "/")
    end
end

function response(status, headers, body)
    if status == 201 then
        local success, resp = pcall(function()
            return body and load("return " .. body)()
        end)
        if success and resp and resp.id then
            wrk.thread:set("id", resp.id)
        end
    end
end