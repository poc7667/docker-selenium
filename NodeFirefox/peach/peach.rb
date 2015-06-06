# -*- encoding : utf-8 -*-
#!/usr/bin/ruby
require 'yaml'
require "json"
require 'pry'
require "selenium-webdriver"
require 'nokogiri'
require 'active_support/all'
require 'yaml'
require 'date'
require 'awesome_print'
require 'mongo'
require '../common_helper'
require '../mongodb_helper'
include Mongo

CONFIG = YAML.load_file('peach_config.yml')
APP_NAME = CONFIG["APP_NAME"]
DB = YAML.load_file('../database.yml')

# res= parse_url_string('http://book.flypeach.com/default.aspx?ao=B2CZHTW&ori=TPE&des=KIX&dep=2015-06-03&adt=1&chd=0&inf=0&langculture=zh-TW&bLFF=false')
# binding.pry
module FormAction
  def form_action(from_city, to_city, flight_date_str)
    one_way_id= "trip_type_oneway"
    from_city_id= "inputFrom"
    to_city_id = "inputTo"
    flight_date_id = "inputDepartingon"
    city_xpth = "href"
    wait = Selenium::WebDriver::Wait.new(:timeout => 3) # seconds
    wait.until { @driver.find_element(:id => one_way_id) }
    @driver.find_element(:id, one_way_id).click # one-way
    # click FROM
    @driver.find_element(:id, from_city_id).click
    from_city_form = @driver.find_element(:xpath,  "//*[@#{city_xpth}=\'#{from_city}\']" )
    from_city_form.click
    # click TO
    2.times do
      @driver.find_element(:id, to_city_id).click
    end
    # 他會藏在最後一個
    to_city_form = @driver.find_elements(:xpath, "//a[@href=\'#{to_city}\']").last
    to_city_form.click
    # set_currency
    remove_readonly_str = 'document.getElementById("inputDepartingon").removeAttribute("readonly")'
    @driver.execute_script(remove_readonly_str)
    set_input_field_value(@driver, flight_date_id, flight_date_str)
    @driver.find_element(:name, "flyinpeach-booking").click # submit
  end

  def click_next_schedule
      @driver.find_elements(:xpath, "//div[@class='datenext']/a").first.click
  end

  def parse_schedules(html)
    begin
      html.css("div.WrapperFlightDate").map(&:text).first.split("~").map(&:strip).collect do |schedule|
        get_clean_schedule_text(schedule)
      end
    rescue Exception => e
      p e.backtrace
      binding.pry
    end
  end

  def get_flight_year(html)
    # "201506" => 2015
    html.css("select#ddlMY_1").css("option").first.attributes["value"].value.to_i/100
  end

  def get_html_source
    begin
    wait = Selenium::WebDriver::Wait.new(:timeout => CONFIG["TIMEOUT"]) # seconds
    wait.until { @driver.find_element(:css => "div.WrapperFlightDate") }
    sleep 1
    Nokogiri::HTML(@driver.page_source)
    rescue Exception => e
        binding.pry
          ap e.message 

        end    
  end

  def get_next_schedules
     sleep 10
    html = get_html_source
    year = get_flight_year(html)
    parse_schedules(html).each do |schedule|
      next unless 3 == schedule.count 
      flight_date = Date.new(year, schedule[0].to_i, schedule[1].to_i)
      id = "#{flight_date}-#{@from_city}-#{@to_city}"
      @last_updated_at = Time.now
      new_data = {:updated_at => @last_updated_at, :price => schedule.last.to_i}
      if exist_in_database?(@collection, id) # update
        @collection.find({_id: id}).update_one(
            { "$push" => { "history" => new_data}},
            :upsert => true, 
            :safe => true
          )
      else
        @collection.insert_one(
          _id: id,
          flight_date: flight_date,
          from: @from_city,
          to: @to_city,
          history:[new_data]
          )
      end
      ap "#{flight_date}:#{new_data}"
    end
  end
end

class Peach  
  include FormAction
  def initialize
    renew_driver
    @date_range = get_date_range(CONFIG["DATE_FORMAT"], 1.week, 1.day)
    @client = Mongo::Client.new([ CONFIG["DB"]["HOST"] ], :database => CONFIG["DB"]["NAME"])
    @collection = @client[CONFIG["DB"]["COLLECTION_NAME"]]
    @from_city = nil
    @task_start_at = Time.now
    @last_updated_at = Time.now
  end

  def run_task
    begin
      get_from_cities_to_cities_and_date_range(CONFIG["CITY"]["FROM"].keys, CONFIG["CITY"]["TO"].keys, [@date_range.first]).each do | from_city, to_city, flight_date_str |
        @from_city, @to_city, @flight_date_str = from_city, to_city, flight_date_str
        form_action(@from_city, @to_city, @flight_date_str) # only for first time
        # cnt = 0
        loop do
          get_next_schedules
          click_next_schedule
          # cnt += 1
          break if ((Time.now - @last_updated_at).to_i > CONFIG["TIMEOUT"])
          # break if cnt > 2
        end
        renew_driver
      end
      add_task_log(@client[:task_log], { _id: "#{APP_NAME}-#{Time.now}",task_name: APP_NAME, elpased_time: Time.now - @task_start_at})
      # add_log# {_id: "#{APP_NAME}-#{Time.now}",task_name: APP_NAME, elpased_time: Time.now - @task_start_at}
    rescue Exception => e
      ap e.message 
      ap e.backtrace
    ensure
      @driver.quit
    end
  end

  private
    def renew_driver
      @driver.quit unless @driver.nil?
      @driver = Selenium::WebDriver.for :firefox
      # @driver = Selenium::WebDriver.for :phantomjs
      @driver.get(CONFIG["ROOT_URL"])
    end
end

Peach.new.run_task
