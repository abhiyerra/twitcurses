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

def update_timeline
  Curses.clear
  header
  Curses.addstr "Last updated: #{Time.now}\n"

  @twitter.friends_timeline.each do |tweet|
    Curses.addstr "#{tweet.user.screen_name}: #{tweet.text}\n"
  end
end

def update_status
  Curses.deleteln
  Curses.deleteln
  Curses.addstr "\n"
  Curses.addstr "Enter a tweet or empty line to cancel: "
  new_tweet = Curses.getstr

  unless new_tweet.eql? ''
    @twitter.update(new_tweet)
  end

  update_timeline
end

begin
  @config = YAML::load_file(ConfigFile)

  @twitter = Twitter::Base.new(Twitter::HTTPAuth.new(@config["username"], @config["password"]))

  Curses.init_screen
  Curses.start_color
  Curses.setpos(0, 0)

  Thread.new do 
    loop do
      update_timeline
      Curses.refresh
      sleep @config["refresh-rate"]
    end
  end

  while true
    c = Curses.getch

    case c
    when ?R
      update_timeline
    when ?S
      update_status
    when ?\e
      Curses.clear
      exit
    end
  end 

  Curses.clear
end
