{
  PORT          = 3000
  API_URL       = "https://api.openweathermap.org/data/2.5/weather"
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
  { q, lat, lon, appid, units='metric' } = ctx.query

  return ctx.body = "appid (your openweathermap api key) is required" unless appid
  return ctx.body = "q (city name) or both lat & lon are required" unless q or (lat and lon)

  { status, data } = await axios.get API_URL, params: { q, lat, lon, appid, units }
  { temp, pressure, feels_like, humidity } = data.main

  ctx.body = """
    # HELP temperature Temperature in degrees Celcius
    # TYPE temperature gauge
    temperature{service="openweathermap"} #{temp}

    # HELP humidity Relative humidity %
    # TYPE humidity gauge
    humidity{service="openweathermap"} #{humidity}

    # HELP feels_like The "feels like" temperature (deg C)
    # TYPE feels_like gauge
    feels_like{service="openweathermap"} #{feels_like}

    # HELP pressure Atmospheric pressure in mbar (millibars)
    # TYPE pressure gauge
    pressure{service="openweathermap"} #{pressure}
  """

#
# Server init
#
app = new Koa
app.use router.routes()
app.listen PORT
