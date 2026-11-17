// Fetch real weather from Open-Meteo
async function getWeather(lat, lon) {
  const url = new URL('https://api.open-meteo.com/v1/forecast');
  url.search = new URLSearchParams({
    latitude: String(lat),
    longitude: String(lon),
    current: 'temperature_2m,apparent_temperature,relative_humidity_2m,precipitation_probability,weather_code,wind_speed_10m',
    daily: 'uv_index_max',
    timezone: 'auto',
  });

  const response = await fetch(url, { signal: AbortSignal.timeout(10000) });
  if (!response.ok) throw new Error(`Weather provider returned ${response.status}`);
  const data = await response.json();
  const current = data.current;
  const uvIndex = data.daily?.uv_index_max?.[0];
  if (!current || !Number.isFinite(current.temperature_2m)) {
    throw new Error('Weather provider returned incomplete data');
  }

  return {
    feelsLike: Math.round(current.apparent_temperature ?? current.temperature_2m),
    rainProb: current.precipitation_probability ?? 0,
    uvIndex: uvIndex ?? 0,
    windSpeed: current.wind_speed_10m ?? 0,
    humidity: current.relative_humidity_2m ?? 0,
  };
}

module.exports = { getWeather };
