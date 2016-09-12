local sha1 = require 'sha1'
local mime = require 'mime'
local cjson = require("cjson.safe")
local http = require("socket.http")


local function getkey(public_key, private_key)
    local hmac_data = sha1.hmac_binary(private_key, public_key)
    local key = mime.b64(hmac_data)
    return key
end


local function get_request_body(area_id, type1)

    local private_key = 'e0badd_SmartWeatherAPI_fe082ad' --你申请的private_key
    local appid = '6f5e74b394627f3a' -- 你申请的appid
    local appid_six = string.sub(appid, 1, 6)
    local area_id = area_id or '101010100' -- 区域代码,beijing


    local type   -- 接口类型  'forecast_v'  'forecast_f' 
    if type1 then
        type = type1 
    else
        type = 'forecast_v'
    end

    local date = os.date("%Y%m%d%H%M", os.time())  -- 日期时间

    local public_key = "http://open.weather.com.cn/data/?areaid=" .. area_id .. "&type=" .. type .."&date=" ..  date .. "&appid=" .. appid

    local key = getkey(public_key, private_key)
    local url = "http://open.weather.com.cn/data/?areaid=" .. area_id .. "&type=" .. type .. "&date=" .. date .. "&appid=" .. appid_six .. "&key=" .. key

    local body, code = http.request(url)
    if body then
        -- print(body)
        return true, body
    else
        return false, xx --TODO
    end
end

local function split( str, delimiter )
    if str == nil or str=='' or delimiter == nil then
        return nil
    end
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end


local weather_code = {
    ["00"] = '晴',
    ["01"] = "多云",
    ["02"] = '阴',
    ["03"] = '阵雨',
    ["04"] = '雷阵雨',
    ["05"] = '雷阵雨伴有冰雹',
    ["06"] = '雨夹雪',
    ["07"] = '小雨',
    ["08"] = '中雨',
    ["09"] = '大雨',
    ["10"] = '暴雨',
    ["11"] = '大暴雨',
    ["12"] = '特大暴雨',
    ["13"] = '阵雪',
    ["14"] = '小雪',
    ["15"] = '中雪',
    ["16"] = '大雪',
    ["17"] = '暴雪',
    ["18"] = '雾',
    ["19"] = '冻雨',
    ["20"] = '沙尘暴',
    ["21"] = '小到中雨',
    ["22"] = '中到大雨',
    ["23"] = '大到暴雨',
    ["24"] = '暴雨到大暴雨',
    ["25"] = '大暴雨到特大暴雨',
    ["26"] = '小到中雪',
    ["27"] = '中到大雪',
    ["28"] = '大到暴雪',
    ["29"] = '浮尘',
    ["30"] = '扬沙',
    ["31"] = '强沙尘暴',
    ["53"] = '霾',
    ["99"] = '无'
}

local wind_code = { 
    ['0'] = '无持续风向',
    ['1'] = '东北风',
    ['2'] = '东风',
    ['3'] = '东南风',
    ['4'] = '南风',
    ['5'] = '西南风',
    ['6'] = '西风',
    ['7'] = '西北风',
    ['8'] = '北风',
    ['9'] = '旋转风'
}

local function getdate(future_days)
    future_days = future_days or 0
    local cur_timestamp = os.time()
    local one_hour_timestamp = 24*60*60
    local temp_time = cur_timestamp + one_hour_timestamp * future_days

    local date = os.date("%Y%m%d", temp_time)
    return date
end

local function process_body( body )
    assert(type(body) == 'string') 
    local t = cjson.decode(body)

    if not t or not t.c or not t.f or not t.f.f0 or not t.f.f1[1] then
        return false, xx --TODO
    end 

    local r = {}
    r.code = t.c.c1  
    r.area = t.c.c3  
    r.city = t.c.c5  
    r.province = t.c.c7 
    r.furture = {}
    for i=1,3 do
        local wind_direction, wind_strength, temperature
        local fe = t.f.f1[i].fe
        local ff = t.f.f1[i].ff
        if fe and ff and fe ~= ff and #fe > 0 and #ff > 0 then  --风向
            wind_direction =  wind_code[fe] .. "转" .. wind_code[ff]
        else
            if fe and #fe > 0 then
                wind_direction =  wind_code[fe]
            elseif ff and #ff > 0 then
                wind_direction = wind_code[ff]
            end
        end
        -----
        local fg = t.f.f1[i].fg  
        local fh = t.f.f1[i].fh
        if fg and fh and fg ~= fh and #fg > 0 and #fh > 0 then  -- 风力
            wind_strength =  fg .. "转" .. fh .. "级"
        else
            if fg and #fg > 0  then
                wind_strength =  fg .. "级"
            elseif fh and #fh > 0 then
                wind_strength = fh .. "级"
            end
        end
        -----
        local fd = t.f.f1[i].fd 
        local fc = t.f.f1[i].fc
        if fd and fc and fd ~= fc and #fd > 0 and #fc > 0 then  -- temperature
            temperature =  fd ..'~' .. fc .. '℃'
        else
            if fd and #fd > 0  then
                temperature =  fd .. '℃'
            elseif fc and #fc > 0 then
                temperature = fc .. '℃'
            end
        end
        r.furture[i] = {
        date    = getdate(i - 1),
        weather = weather_code[t.f.f1[i].fa],
        temperature = temperature,
        wind    =  wind_direction.. ",风力" ..wind_strength,
        ["最高温度"] = #fc >0 and fc .. '℃' or '',
        ["最低温度"] = #fd >0 and fd .. '℃' or '',
        ["风向"]    = wind_direction,
        ["风力"]    = wind_strength,
        ["天气"]    = weather_code[t.f.f1[i].fa]
    }
    end
    r.today = r.furture[1]
    return r
end

local filename = "weather.code.list"
local file = io.open(filename, "r")
if file then
    for line in file:lines() do
        if #line > 0 then
            local tbl = split(line, " ")
            if tbl[1] ~= '#' then
                local ok, body = get_request_body(tbl[1])
                -- print(body)
                if ok then
                    -- TODO
                    local result = process_body(body)
                    print(cjson.encode({result = result}))
                    -- print('ok')
                else
                    local ok, body = get_request_body(tbl[1],'forecast_f')
                    if ok then
                         local result = process_body(body)
                        print(cjson.encode({result = result}))
                    else
                        print('not ok -- '..line)
                    end
                end
            end
        end
    end
else
    return false, nil
end
file:close()