// Fetch real weather from Open-Meteo
const CACHE_TTL_MS = 10 * 60 * 1000;
const weatherCache = new Map();
const inFlightRequests = new Map();

async function getWeather(lat, lon) {
  // Round coordinates to keep nearby requests from creating duplicate cache entries.
  const cacheKey = `${Number(lat).toFixed(2)},${Number(lon).toFixed(2)}`;
  const cached = weatherCache.get(cacheKey);
  if (cached && cached.expiresAt > Date.now()) return cached.value;
  if (inFlightRequests.has(cacheKey)) return inFlightRequests.get(cacheKey);

  const request = fetchWeather(lat, lon, cacheKey);
  inFlightRequests.set(cacheKey, request);
  try {
    return await request;
  } finally {
    inFlightRequests.delete(cacheKey);
  }
}

async function fetchWeather(lat, lon, cacheKey) {
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

  const result = {
    feelsLike: Math.round(current.apparent_temperature ?? current.temperature_2m),
    rainProb: current.precipitation_probability ?? 0,
    uvIndex: uvIndex ?? 0,
    windSpeed: current.wind_speed_10m ?? 0,
    humidity: current.relative_humidity_2m ?? 0,
  };

  weatherCache.set(cacheKey, { value: result, expiresAt: Date.now() + CACHE_TTL_MS });
  return result;
}

module.exports = { getWeather };
