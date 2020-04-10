#!/bin/env ruby
# encoding: utf-8

Shoes.setup do
  gem 'httparty'
  gem 'certified'
  gem 'tzinfo'
  gem 'i18n'
end

require 'httparty'
require 'certified'
require 'tzinfo'
require 'i18n'
require 'json'

I18n.load_path = ['ko.yml']
I18n.locale = :ko

#todo: how to programmatically get mirrorid?
MIRROR_ID = "mmow_1234"
WEATHER_API_URL = "https://mmowapi.herokuapp.com/weather?mirrorId=#{MIRROR_ID}"
AQ_API_URL = "https://mmowapi.herokuapp.com/aq?mirrorId=#{MIRROR_ID}"

weather = HTTParty.get(WEATHER_API_URL, :verify => false)
if weather["timezone"].empty?
  WEATHER_API_URL = "https://mmowapibackup.herokuapp.com/weather?mirrorId=#{MIRROR_ID}"
  AQ_API_URL = "https://mmowapibackup.herokuapp.com/aq?mirrorId=#{MIRROR_ID}"
  weather = HTTParty.get(WEATHER_API_URL, :verify => false)
end
TIMEZONE = TZInfo::Timezone.get(weather["timezone"])

aq = HTTParty.get(AQ_API_URL, :verify => false)

class Clock
  def initialize(timezone)
    @timezone = timezone
  end
  def get_time
    @timezone.now.strftime("%l:%M %p")
  end

  def get_month
    @timezone.now.strftime("%h")

  end

  def get_date
    @timezone.now.strftime("%e")
  end

  def get_day
    @timezone.now.strftime("%A")
  end

  def convert_unixtime(unixtime)
    @timezone.utc_to_local(Time.at(unixtime).utc).strftime("%l %p")
  end
end

Shoes.app do
  #todo : fix
  self.fullscreen = true if Time.now.zone == 'UTC'

  background black
  clock = Clock.new(TIMEZONE)

  #current weather info
  @current_icon = flow do
    image "assets/#{weather["current_icon"]}.png", width: 70, height: 70, left: 190, top: 225
  end

  stack(width: 450)do
    flow do
      stack(left: 10, top: 165) do
        @temp = para "#{weather["temp"]}°C", stroke: white, font: "NanumSquare", size: 50, margin_top: 60
        @summary = para weather["summary"], stroke: white, font: "NanumSquareBold", size: 12, margin_top: 10, margin_bottom: 20
      end

      @hourly_data = flow do
        weather["hourly_data"].each do |data|
          stack(width: 70) do
            para clock.convert_unixtime(data["time"]), stroke: white, font: "NanumSquareBold", size: 13, align: 'center', margin_left: 10
            image "assets/#{data['icon']}.png", width: 20, height: 20, top: 35, left: 30
            para "#{data["temperature"].round}°C", stroke: white, font: "NanumSquareBold", size: 13, align: 'center', margin_top: 28, margin_left: 13
          end
        end
      end
    end



  end

  stack(width: 340) do
    flow(right: 20, top: 195) do
      @address = para weather["address"], font: "NanumSquareBold", stroke: white, size: 12, align: 'right'
    end

    # dust info
    flow(right: 10, top: 380) do
      stack(width: 310) do
        para "미세먼지", stroke: white, font: "NanumSquareBold", size: 13, align: 'right', margin_right: 10
      end
      @dust = stack(width: 30) do
        image "assets/#{aq["pm10"]}.png", width: 20, height: 20, align: 'right', top: 3
      end
    end

    # uv info
    flow(right: 10, top: 407) do
      stack(width: 310) do
        para "자외선", stroke: white, font: "NanumSquareBold", size: 13, align: 'right', margin_right: 10
      end
      @uv = stack(width: 30) do
        image "assets/#{weather["uv"]}.png", width: 20, height: 20, align: 'right', top: 3
      end
    end

    # humidity info
    flow(right: 10, top: 434) do
      stack(width: 310) do
        para "습도", stroke: white, font: "NanumSquareBold", size: 13, align: 'right', margin_right: 10
      end
      @humidity = stack(width: 30) do
        image "assets/#{weather["humidity"]}.png", width: 20, height: 20, align: 'right', top: 3
      end
    end

    # time info
    flow(right: 20, top: 225) do
      @counter = para "#{clock.get_time}", stroke: white, font: "NanumSquare", :align => 'right', size: 50
      every(3) do
        @counter.replace "#{clock.get_time}"
      end
    end

    # date info
    flow(right: 20, top: 300) do
      @date = para(I18n.t("month_names.#{clock.get_month}") + " " + I18n.t("date_names.#{clock.get_date}") + " " + I18n.t("day_names.#{clock.get_day}"), stroke: white, font: "NanumSquareBold", :align => 'right', margin_top: 10, size: 18)
      every(60) do
        @date.replace I18n.t("month_names.#{clock.get_month}") + " " + I18n.t("date_names.#{clock.get_date}") + " " + I18n.t("day_names.#{clock.get_day}")
      end
    end
  end

  # update weather
  every(30) do
    download WEATHER_API_URL do |dump|
      weather = JSON.parse(dump.response.body)
      clock = Clock.new(TZInfo::Timezone.get(weather["timezone"]))

      @current_icon.clear {
        flow do
          image "assets/#{weather["current_icon"]}.png", width: 70, height: 70, left: 190, top: 225
        end
      }

      @temp.replace "#{weather["temp"]}°C"
      @summary.replace weather["summary"]
      @address.replace weather["address"]

      @hourly_data.clear {
        flow do
          weather["hourly_data"].each do |data|
            stack(width: 70) do
              para clock.convert_unixtime(data["time"]), stroke: white, font: "NanumSquareBold", size: 13, align: 'center', margin_left: 10
              image "assets/#{data['icon']}.png", width: 20, height: 20, top: 35, left: 30
              para "#{data["temperature"].round}°C", stroke: white, font: "NanumSquareBold", size: 13, align: 'center', margin_top: 28, margin_left: 13
            end
          end
        end
      }

      @uv.clear {
        stack(width: 30) do
          image "assets/#{weather["uv"]}.png", width: 20, height: 20, align: 'right', top: 3
        end
      }

      @humidity.clear {
        stack(width: 30) do
          image "assets/#{weather["humidity"]}.png", width: 20, height: 20, align: 'right', top: 3
        end
      }
    end
  end

  every(30) do
    download AQ_API_URL do |dump|
      aq = JSON.parse(dump.response.body)
      @dust.clear {
        stack(width: 30) do
          image "assets/#{aq["pm10"]}.png", width: 20, height: 20, align: 'right', top: 3
        end
      }
    end
  end
end

