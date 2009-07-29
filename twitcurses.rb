#!/usr/bin/env ruby

# TODO
#   - different colors for individuals
#   - show current length of the tweet
##   - mentions page
#       - all the mentions
#       - color. if a reply has been made then normal
#               if a reply has not been made then yellow or red
#
#
require 'date'
require 'rubygems'
require 'yaml'
require 'curses'
require 'twitter'

ConfigFile = "#{ENV['HOME']}/.twitcurses"

def header
  Curses::addstr("Twitcurses by abhiyerra\n\n")
end

def create_refresher_thread
  @refresher = Thread.new do 
    loop do
      update_timeline
      Curses.refresh
      sleep @config["refresh-rate"]
    end
  end
end

def destroy_refresher_thread
  Thread.kill @refresher
end

def restart_refresher_thread
  destroy_refresher_thread
  create_refresher_thread
end

def update_timeline
  Curses.clear
  header
  Curses.addstr "Last updated: #{Time.now}\n"

  @twitter.friends_timeline.each do |tweet|
    tweet_text = "#{tweet.user.screen_name}: #{tweet.text}\n"
    Curses.addstr tweet_text

    if @updated_time <= DateTime.parse(tweet.created_at)
      `say "#{tweet_text}"`
    end
  end

  @updated_time = DateTime.parse(Time.now.to_s)
end

def update_status
  destroy_refresher_thread

  Curses.deleteln
  Curses.addstr "\n"
  Curses.addstr "Enter a tweet or empty line to cancel: "
  new_tweet = Curses.getstr

  unless new_tweet.eql? ''
    @twitter.update(new_tweet)
  end

  create_refresher_thread
end

begin
  @config = YAML::load_file(ConfigFile)

  @twitter = Twitter::Base.new(Twitter::HTTPAuth.new(@config["username"], @config["password"]))
  @updated_time = DateTime.parse(Time.now.to_s)
  
  Curses.init_screen
  Curses.start_color
  Curses.setpos(0, 0)

  create_refresher_thread

  while true
    c = Curses.getch

    case c
    when ?R
      restart_refresher_thread
    when ?T
      update_status
    when ?\e
      Curses.clear
      exit
    end
  end 

  Curses.clear
end
