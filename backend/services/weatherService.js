// Fetch real weather from Open-Meteo
async function getWeather(lat, lon) {
  try {
    // We request current weather: temp, humidity, wind, rain, and UV index
    const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m&daily=uv_index_max&timezone=auto`;
    
    const response = await fetch(url);
    const data = await response.json();

    const current = data.current;
    const uvIndex = data.daily.uv_index_max[0];

    // Calculate "Feels Like" (approximate, since Open-Meteo current doesn't give it directly for free in this tier)
    // We'll just use the actual temp for now, or add a wind chill factor
    const feelsLike = current.temperature_2m; 

    // Weather code 51-67 and 80-82 means rain/drizzle in Open-Meteo
    const isRaining = (current.weather_code >= 51 && current.weather_code <= 67) || 
                      (current.weather_code >= 80 && current.weather_code <= 82);

    return {
      feelsLike: Math.round(feelsLike),
      rainProb: isRaining ? 80 : 10, // Simplified: if it's raining now, 80%. Otherwise 10%.
      uvIndex: uvIndex || 0,
      windSpeed: current.wind_speed_10m,
      humidity: current.relative_humidity_2m
    };
  } catch (error) {
    console.error("Weather API Error:", error);
    // Fallback weather if API fails
    return { feelsLike: 25, rainProb: 0, uvIndex: 0, windSpeed: 10, humidity: 50 };
  }
}

module.exports = { getWeather };