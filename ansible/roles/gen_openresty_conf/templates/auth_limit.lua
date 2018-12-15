-- openresty rate limit

local str_len = string.len
local str_sub = string.sub

local function auth()
    local h, err = ngx.req.get_headers()
    if err ~= nil then
        return nil, 'get header err'
    end

    local token = h['API-KEY']

    if token == nil then
        return nil, 'api key not found'
    end

    if str_len(token) < 8 then
        return nil, 'invalid key'
    end

    return str_sub(token, 1, 8), nil
end


local token, err = auth()
local cjson = require('cjson')
local json_encode = cjson.encode

local function error(status, error, message, data)
    data = data or message

    ngx.status = status
    ngx.say(json_encode({
        error=error,
        message=message,
        data=data
    }))
    return ngx.exit(status)
end

if err then
    ngx.log(ngx.ERR, err)
    return error(403, "HEADER_INVALID", "Header error: the request header is invalid.")
end

local ratelimit = require "redis_limit"

local lim, err = ratelimit.new("ratelimit", "{{ hostvars[inventory_hostname].lua_rate_limit }}r/s", {{ hostvars[inventory_hostname].lua_rate_burst }}, 0)
if not lim then
    ngx.log(ngx.ERR,
            "failed to instantiate a resty.redis.limit object: ", err)
    return error(500, "INTERNAL_SERVER_ERROR", "Internal error: internal server error.")
end

local red = { host = "{{ hostvars[inventory_hostname].lua_redis_host }}", port = 6379, timeout = 1 }

local delay, err = lim:incoming(token, red)

if delay == nil then
    if err == "rejected" then
        return error(429, "TOO_MANY_REQUEST", "too many requests")
    end
    ngx.log(ngx.ERR, "failed to limit req: ", err)
    return error(500, "INTERNAL_SERVER_ERROR", "Internal error: internal server error.")
end

if delay >= 0.001 then
    -- the 2nd return value holds the number of excess requests
    -- per second for the specified key.
    local excess = err

    ngx.sleep(delay)
end
