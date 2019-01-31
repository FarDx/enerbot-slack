ADM_LOG = ENV['SLACK_LOG_BOT']
BOT_ADMINS = ENV['SLACK_USERS']
BOT_CHANNELS = ENV['SLACK_CHANNELS']
SUPER_COMMAND = ENV['SUPER_COMMAND']
SUPER_USER = ENV['SUPER_USER']

# Admin stuff
module Admin
  def session(user)
    open('black_list.log', 'a') do |f|
      regex = /(?<=\@).*(?=>)/
      user = regex.match(user)[0] if user =~ regex
      f.puts "#{user}\n" unless user =~ /#{ENV['SUPER_USER']}/
    end
  end

  def self.times(data)
    open('black_list.log').grep(/^(#{data})/)
  end

  def reset(user)
    regex = /(?<=\@).*(?=>)/
    user = regex.match(user)[0] if user =~ regex
    p user
    open('black_list.log') do |file|
      var = ''
      file.each_line do |line|
        var += line.gsub(user, 'CENSORED')
        p var
      end
      open('black_list.log', 'w') { |file| file.puts var }
    end
  end
end

# Handles all the magical logic for permissions
class Redirect
  extend Admin

  def initialize(data)
    @user = data.user
    @channel = data.channel
    @command = data.text

    @check_admin = BOT_ADMINS.include?(@user)
    @check_ban = Admin.times(@user).empty?
    @check_channel = BOT_CHANNELS.include?(@channel)
    @check_super = /enersay|enerban|enerrest|enershut/.match?(@command)
  end

  def shift
    if @check_admin == false && @check_super == true
      Redirect.session(@user) if @command =~ /enerban/
      Enerbot.message(ADM_LOG, "User <@#{@user}> is trying to do something nasty on <##{@channel}|#{@channel}>")
    elsif @check_ban == false
      Enerbot.message(@channel, "*User:* <@#{@user}> is banned until i forget it :x:")
    elsif @check_channel == false
      Enerbot.message(ADM_LOG, "User <@#{@user}> is making me work on <##{@channel}|#{@channel}>")
      nil
    end
  end
end

# Send message with response if it's valid
class Reply
  extend Admin
  def initialize(data)
    text = data.text
    user = data.user

    validations = Redirect.new(data)
    check = validations.shift

    if text =~ /#{ENV['SUPER_COMMAND']}/ && check.nil?
      case text
      when /enerban/
        Reply.session(text)
      when /enerrest/
        Reply.reset(text)
      when /enershut/
        Enerbot.message(data, Case.kill(text)) && abort('bye')
      when /enersay/
        match = text.match(/enersay (\<[#@])?((.*)\|)?(.*?)(\>)? (.*?)$/i)
        unless match.nil?
          chan = match.captures[2] || match.captures[3]
          message = match.captures[5]
        end
        Enerbot.message(chan, message)
      end
    else
      value = Case.bot(data)
      Reply.session("-#{user}")
      attempts = Admin.times("-#{user}").size
      Reply.session(user) if attempts > 4
      unless value.nil?

        Enerbot.message(data, value) if check.nil?
      end
    end
  end
end
