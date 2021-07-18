{
  PORT          = 3000
  API_URL       = "https://api.openweathermap.org/data/2.5"
  NODE_ENV      = 'development'
} = process.env

axios   = require 'axios'
Koa     = require 'koa'
router  = do require 'koa-router'

#
# Routes
#
router.get '/', root = (ctx)->
  ctx.body = """
  Usage:

    GET   /
      this message

    GET   /metrics
      weather data in prometheus format
      Params set via prometheus.yml - see included example config
  """

router.get '/metrics', (ctx)->
  { q, lat, lon, appid, units='metric' } = ctx.query # weather params
  { polution } = ctx.query # include polution data?
  { location, service="openweathermap" } = ctx.query # pass-through attrs

  return ctx.body = "appid (your openweathermap api key) is required" unless appid
  return ctx.body = "q (city name) or both lat & lon are required" unless q or (lat and lon)

  # fetch weather data
  { status, data } = await axios.get "#{API_URL}/weather", params: { q, lat, lon, appid, units }
  { temp: temperature, pressure, feels_like, humidity } = data.main

  # grab openweathermap's interpretation of lat/lon
  # for the pollution call if we don't already have it
  { lon, lat } = data.coord unless lat and lon

  #
  # helpers
  #
  attrs = ->
    ret = []
    for key, val of { location, service, lat, lon, q, units } when val
      ret.push "#{key}=\"#{val}\"" if val?
    ret.join()

  gauge = (name, value, description)->
    """
    # HELP #{name} #{description}
    # TYPE #{name} gauge
    #{name}{#{attrs()}} #{value}
    """

  temp_unit_names =
    standard: 'Kelvin'
    metric:   'Celsius'
    imperial: 'Fahrenheit'

  blocks = [
    gauge 'temperature',  temperature,  "Temperature (°#{temp_unit_names[units]})"
    gauge 'humidity',     humidity,     'Relative humidity (%)'
    gauge 'feels_like',   feels_like,   "The 'feels like' temperature (°#{temp_unit_names[units]})"
    gauge 'pressure',     pressure,     'Atmospheric pressure (mbar)'
  ]

  if polution?
    # fetch air quality data
    { status, data } = await axios.get "#{API_URL}/air_pollution", params: { lat, lon, appid }
    { main: { aqi }, components: { co, no: nox, no2, o3, so2, pm2_5, pm10, nh3 } } = data.list[0]

    blocks = blocks.concat [
      gauge 'aqi',    aqi,    'Air Quality Index from 1 (good) to 5 (very poor)'
      gauge 'co',     co,     'Carbon monoxide (μg/m³)'
      gauge 'no',     nox,    'Nitrogen monoxide (μg/m³)'
      gauge 'no2',    no2,    'Nitrogen dioxide (μg/m³)'
      gauge 'o3',     o3,     'Ozone (μg/m³)'
      gauge 'so2',    so2,    'Sulphur dioxide (μg/m³)'
      gauge 'pm2_5',  pm2_5,  'Fine particulates 2.5μm (μg/m³)'
      gauge 'pm10',   pm10,   'Coarse particulates 10μm (μg/m³)'
      gauge 'nh3',    nh3,    'Ammonia (μg/m³)'
    ]

  ctx.body = blocks.join '\n\n'

#
# Server init
#
app = new Koa
app.use router.routes()
app.listen PORT
