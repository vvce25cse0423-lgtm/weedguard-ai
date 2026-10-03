// Supabase Edge Function: weather
// Deploy: supabase functions deploy weather

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const OPENWEATHER_KEY = Deno.env.get("OPENWEATHER_API_KEY") ?? "624d64f50bcf3cf596ccf7693dce142f";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const { lat, lon } = await req.json();
    if (!lat || !lon) {
      return new Response(JSON.stringify({ error: "lat and lon are required" }), { status: 400 });
    }

    const currentRes = await fetch(
      `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${OPENWEATHER_KEY}&units=metric`
    );
    const current = await currentRes.json();

    const forecastRes = await fetch(
      `https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&appid=${OPENWEATHER_KEY}&units=metric&cnt=24`
    );
    const forecastData = await forecastRes.json();

    const dayMap: Record<string, { maxTemp: number; minTemp: number; rainProb: number; desc: string }> = {};
    for (const item of forecastData.list ?? []) {
      const day = item.dt_txt.split(" ")[0];
      if (!dayMap[day]) {
        dayMap[day] = { maxTemp: item.main.temp_max, minTemp: item.main.temp_min, rainProb: (item.pop ?? 0) * 100, desc: item.weather[0].description };
      } else {
        dayMap[day].maxTemp = Math.max(dayMap[day].maxTemp, item.main.temp_max);
        dayMap[day].minTemp = Math.min(dayMap[day].minTemp, item.main.temp_min);
      }
    }

    const forecast = Object.entries(dayMap).slice(0, 4).map(([date, d]) => ({
      date,
      max_temp: Math.round(d.maxTemp * 10) / 10,
      min_temp: Math.round(d.minTemp * 10) / 10,
      rain_probability: Math.round(d.rainProb),
      description: d.desc,
    }));

    const result = {
      temperature: Math.round(current.main.temp * 10) / 10,
      humidity: current.main.humidity,
      rain_probability: forecast[0]?.rain_probability ?? 0,
      wind_speed: Math.round((current.wind.speed * 3.6) * 10) / 10,
      description: current.weather[0].description,
      icon: current.weather[0].main.toLowerCase(),
      forecast,
    };

    return new Response(JSON.stringify(result), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: "Weather fetch failed" }), {
      status: 500,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }
});
