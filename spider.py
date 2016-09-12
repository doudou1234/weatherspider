# -*- coding: UTF-8 -*- 

import urllib
import urllib2
import datetime
import base64
import hmac
import hashlib
import codecs
import time

private_key = 'e0badd_SmartWeatherAPI_fe082ad' #你申请的private_key
appid = '6f5e74b394627f3a' # 你申请的appid
appid_six = appid[:6]
area_id = '101310215' # 区域代码
type_ = 'forecast_v' # 接口类型
date = datetime.datetime.now().strftime("%Y%m%d%H%M") # 日期时间
date = '201603151428'# 日期时间

public_key = "http://open.weather.com.cn/data/?areaid=" + area_id + "&type=" + type_ +"&date=" + date + "&appid=" + appid
key = urllib.quote(
    hmac.new(private_key, public_key, hashlib.sha1).digest().encode('base64').rstrip()
)
key = 'Ao8MsQ7aEIYpgAJL9zvm7oICgPk='
url = "http://open.weather.com.cn/data/?areaid=" + area_id + "&type=" + type_ + "&date=" + date + "&appid=" + appid_six + "&key=" + key
req = urllib2.urlopen(url)
page = req.read()
if page:
    print page

