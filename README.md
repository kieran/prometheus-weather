# Prometheus Weather

A shim service that translates OpenWeatherMap.org data into a format Prometheus can read

You will need an `API_KEY` to access the api (which has a generous free tier)

Get yours at https://openweathermap.org/api

## General idea

OWM provides weather data in JSON format - but I want to ingest it into Prometheus for use with my own [internal sensor data](https://github.com/kieran/sauron#prometheus--grafana)

OWM JSON data looks like this:
```js

{
  // ...
  "main": {
    "temp": 26.55,
    "feels_like": 29.32,
    // ...
    "pressure": 1023,
    "humidity": 80
  },
  // ...
}
```

Prometheus ingests data that looks like this:
```plain
# HELP temperature Temperature in degrees Celcius
# TYPE temperature gauge
temperature{service="openweathermap"} 26.55

# HELP humidity Relative humidity %
# TYPE humidity gauge
humidity{service="openweathermap"} 80

# HELP feels_like The "feels like" temperature (deg C)
# TYPE feels_like gauge
feels_like{service="openweathermap"} 29.32

# HELP pressure Atmospheric pressure in mbar (millibars)
# TYPE pressure gauge
pressure{service="openweathermap"} 1023
```

This service is a simple Koa server that effectively wraps the OWM API, converting the results into the Prometheus-readable format above.

The `API_KEY` (and other config vars) are set via [your local prometheus.yml](https://github.com/kieran/prometheus-weather/blob/main/example-prometheus.yml), so in theory one service could serve any number of prometheus clients / configs.

## Deployment / Hosting

I deployed this to AWS Lambda using [apex `up`](https://github.com/apex/up) - even hitting it every 15s keeps me _well within_ AWS's free tier.

You could deploy it anywhere a node service can run, including your local machine / network. I just prefer the hands-off nature of lambda.


## Example test reqs

http://localhost:3000/metrics?lat=43.64&lon=-79.41&appid=API_KEY

http://localhost:3000/metrics?q=Toronto&appid=API_KEY

http://localhost:3000/metrics?q=Victoria,BC,CA&appid=API_KEY

