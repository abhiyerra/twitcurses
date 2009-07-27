#!/usr/bin/env ruby

# TODO
#   - different colors for individuals
#   - show replies
#   - show current length of the tweet
#   - reply feature?
#
require 'rubygems'
require 'yaml'
require 'curses'
require 'twitter'
require 'highline/import'

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
    Curses.addstr "#{tweet.user.screen_name}: #{tweet.text}\n"
  end
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
