cfg=require "config"
import sleep from require "socket"
import random from require "math"
import mixin_object from require "moon"

class kitten
  new: (@srv,@nick="kitten",@owner="nonchip")=>
    print "kitten loaded, nick:",@nick
    print "our human is called:",@owner
    mixin_object @,@srv,{
      "join"
      "sendChat"
      "send"
      "sendNotice"
      "connect"
      "trackUsers"
    }
    @cooldowns={}
  gethooks: ()=> {"OnRaw","OnChat","OnNotice"}
  think: (time)=>
    @srv\think!
    for k,_ in pairs(@cooldowns)
      @cooldowns[k]-=time
  start: ()=>
    @sendChat "NickServ", "IDENTIFY kitten86321"
    @sendAction @owner, "joins the server and purrs at you."
    for c in *cfg.autojoin
      @join c
  sendAction:(target,msg)=>
    @send "PRIVMSG %s :\1ACTION %s\1"\format target, msg
  getChanFix:=> cfg.chanfix
  OnRaw: (line)=>
    print "R: %s"\format line
    words=[word for word in line\gmatch("%S+")]
    if words[2]=="INVITE" and words[3]==@nick
      chan=words[4]\sub(2)
      @sendAction @owner, "just got invited to %s by %s."\format chan, words[1]
      @join chan
      return true
    nil
  OnNotice: (user, channel, message)=>
    print "N[%s] %s: %s"\format channel, user.nick, message
  OnChat: (user, channel, message)=>
    print "C[%s] %s: %s"\format channel, user.nick, message
    words=[word for word in message\gmatch("%S+")]
    nickprefix="!"..@nick\sub(1,1)
    if channel==@nick or words[1]==nickprefix
      @sendChat @owner, "[%s@%s] %s"\format user.nick,channel,message
      if words[1]==nickprefix
        table.remove(words,1)
      switch words[1]
        when "help"
          @sendNotice user.nick,"I'm "..@nick..", a friendly bot controlled by "..@owner.."."
          @sendNotice user.nick,"send commands via '/msg "..@nick.."' or in any channel when prefixed with '"..nickprefix.."'"
          @sendNotice user.nick,"commands:"
          @sendNotice user.nick," reload       - should be obvious"
          @sendNotice user.nick," chanfix <c>  - invites/ops a hardcoded list of users for channel <c> (default current channel)"
          @sendNotice user.nick," raw <msg>    - *sends <msg> raw to the server ("..@owner.." only)"
        when "reload"
          @srv\reload!
        when "chanfix"
          c=words[2] or channel
          f=@getChanFix![c]
          if f then
            for u in *f
              @send "INVITE %s %s"\format  u,c
              @send "MODE %s +o %s"\format c,u
        when "raw"
          if user.nick==@owner
            @send table.concat [a for i, a in ipairs words when i > 1], " "
    else
      @cooldowns.randomchat or={}
      @cooldowns.randomchat[channel] or=0
      if message\match @nick
        @cooldowns.randomchat[channel]-=100
      if @cooldowns.randomchat[channel] <=200
        @cooldowns.randomchat[channel] = 0
      if @cooldowns.randomchat[channel] <=0
        @cooldowns.randomchat[channel]=300
        switch random 30
          when 1
            @cooldowns.randomchat[channel]+=100
          when 2
            @sendChat channel, "Mew?"
          when 3
            @sendChat channel, "Mew."
          when 4
            @sendChat channel, "Mrrrrew!"
          when 5
            @sendAction channel, "coils up in a corner."
          when 6
            @sendAction channel, "scratches at the wallpaper."
          when 7
            @sendAction channel, "purrs."
          when 8
            @sendChat channel, "Fchhhhh!"
          else
            @cooldowns.randomchat[channel]=0

return kitten
