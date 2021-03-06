--
-- Copyright (c) 2009-2015 Nous Xiong (348944179 at qq dot com)
--
-- Distributed under the Boost Software License, Version 1.0. (See accompanying
-- file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
--
-- See https://github.com/nousxiong/gce for latest version.
--

local gce = require('gce')
local asio = require('asio')

gce.actor(
  function ()
    local size = 10
  	local tmr = asio.timer()
    local echo_list = {}
    local ec, sender, args, msg

    for i=1, size do
      local aid = gce.spawn('test_lua_asio/timer_actor.lua', gce.monitored)
      gce.send(aid, 'init')
      echo_list[i] = aid
    end

    for n=1, 10 do
      for i=1, size do
        gce.send(echo_list[i], 'echo', 'hi')
      end

      for i=1, size do
        ec, sender, args, msg = 
          gce.match('echo').guard(echo_list[i]).recv('')
        assert(ec == gce.ec_ok, ec)
        assert(msg:getty() == gce.atom('echo'))

        assert(args[1] == 'hi')

        tmr:async_wait(gce.millisecs(10))
        ec, sender, args = gce.match(asio.as_timeout).recv(gce.errcode)
        assert(ec == gce.ec_ok, ec)

        local err = args[1]
        assert(err == gce.err_nil, err)
      end
    end

    for i=1, size do
      gce.send(echo_list[i], 'quit')
      gce.recv(gce.exit)
    end
  end)
