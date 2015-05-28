irc=require "irc"
import sleep from require "socket"
import random from require "math"
import bind_methods from require "moon"

mkKitten=(server,owner="nonchip",nick="kitten")->
  sraw = irc.new nick: nick
  local s
  sraw.reload=()=>
    if s
      for _,h in pairs(s._hooks)
        sraw\unhook unpack h
    package.loaded["kitten"]=nil
    s=(require "kitten") @,nick,owner
    s._hooks={}
    s._bound=bind_methods s
    for i,h in pairs s\gethooks!
      sraw\hook h, i, s._bound[h]
      table.insert(s._hooks,{h,i})
  sraw\reload!
  s\connect server
  s\trackUsers true
  s\join owner if owner\sub(1,1)=="#"
  s\start!
  return s

bots={
  pcall ()-> mkKitten "irc.hackint.net"
  --pcall ()-> mkKitten "chat.freenode.net"
  --pcall ()-> mkKitten "irc.proops.eu"
}

while true
  for _,s in pairs(bots)
    pcall ()-> s\think 0.5
  sleep 0.5
