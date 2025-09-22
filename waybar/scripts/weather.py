#!/usr/bin/env python3
import json
import requests
from datetime import datetime

# Configurações
API_KEY = "ADD HERE YOUR API KEY"  # Substitua pela sua chave do OpenWeatherMap
CITY_LAT = 
CITY_LON = 
CITY_NAME = "ADD HERE YOUR CITY NAME"

# Mapeamento de códigos de clima para ícones Nerd Fonts
WEATHER_ICONS = {
    # Ensolarado
    "01d": "󰖙",  # sol
    "01n": "󰖔",  # lua
    # Parcialmente nublado
    "02d": "󰖕",  # sol com nuvem
    "02n": "󰼱",  # lua com nuvem
    # Nublado
    "03d": "󰖐",  # nuvem
    "03n": "󰖐",  # nuvem
    "04d": "󰖐",  # nuvens
    "04n": "󰖐",  # nuvens
    # Chuva leve
    "09d": "󰖗",  # chuva
    "09n": "󰖗",  # chuva
    # Chuva
    "10d": "󰖖",  # sol com chuva
    "10n": "󰖗",  # chuva noturna
    # Tempestade
    "11d": "󰖓",  # raio
    "11n": "󰖓",  # raio
    # Neve
    "13d": "󰖘",  # neve
    "13n": "󰖘",  # neve
    # Neblina
    "50d": "󰖑",  # neblina
    "50n": "󰖑",  # neblina
}

def get_weather():
    try:
        # URL da API do OpenWeatherMap
        url = f"https://api.openweathermap.org/data/2.5/weather?lat={CITY_LAT}&lon={CITY_LON}&appid={API_KEY}&units=metric&lang=pt_br"
        
        # Fazer requisição
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        
        data = response.json()
        
        # Extrair informações
        temp = round(data['main']['temp'])
        description = data['weather'][0]['description'].title()
        icon_code = data['weather'][0]['icon']
        feels_like = round(data['main']['feels_like'])
        humidity = data['main']['humidity']
        
        # Obter ícone
        icon = WEATHER_ICONS.get(icon_code, "󰖗")  # padrão: chuva
        
        # Formatar saída
        output = {
            "text": f"{icon}  {temp}°C",
            "tooltip": f"{CITY_NAME}\n{description}\nSensação térmica: {feels_like}°C\nUmidade: {humidity}%\nAtualizado: {datetime.now().strftime('%H:%M')}",
            "class": "weather"
        }
        
        return output
        
    except requests.exceptions.RequestException:
        # Erro de conexão/internet
        return {
            "text": "󰖗  N/A",
            "tooltip": f"{CITY_NAME}\nSem conexão com a internet\nTentativa: {datetime.now().strftime('%H:%M')}",
            "class": "weather-error"
        }
    except Exception as e:
        # Outros erros
        return {
            "text": "󰖗  N/A",
            "tooltip": f"{CITY_NAME}\nErro: {str(e)}\nTentativa: {datetime.now().strftime('%H:%M')}",
            "class": "weather-error"
        }

if __name__ == "__main__":
    weather_data = get_weather()
    print(json.dumps(weather_data))
