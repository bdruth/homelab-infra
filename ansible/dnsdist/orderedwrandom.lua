-- dnsdist server policy - orderedwrandom
-- Retrieved from: https://github.com/tbaschak/dnsdist-configs/
-- Forked from: https://github.com/sysadminblog/dnsdist-configs/
--
-- This function is a server policy very similar to the build in policy "wrandom".
-- The difference is this function will take the server server orders into account before
-- distributing queries to the appropriate servers in a pool. My use case for this is I have
-- 3 DNS servers. I want only two servers to take all queries, the third server should only
-- be used in the situation that the two primary servers are down.
--
-- To use this:
--	1. Copy the orderedwrandom.lua file to /etc/dnsdist/
--	2. Edit dnsdist.conf and set the following:
--		- Tell dnsdist to run the orderedwrandom.lua code: dofile('/etc/dnsdist/orderedwrandom.lua')
--		- Set the server policy: setServerPolicyLua("orderedwrandom", orderedwrandom)
--		- Ensure that the servers have an appropriate order set
--
-- As an example, with 3 DNS servers you want all queries to go to "dns1" and "dns2" when they are up.
-- If they are both down, then queries should go to "dns3". The configuration would look like:
--
-- dofile('/etc/dnsdist/orderedwrandom.lua')
-- setServerPolicyLua("orderedwrandom", orderedwrandom)
--
-- newServer({address="192.168.1.1:5356", name="dns1", pool="recursor", checkType="A", checkName="a.root-servers.net.", mustResolve=true, tcpRecvTimeout=10, tcpSendTimeout=10, retries=5, useClientSubnet=true, order=1})
-- newServer({address="192.168.1.2:5356", name="dns2", pool="recursor", checkType="A", checkName="a.root-servers.net.", mustResolve=true, tcpRecvTimeout=10, tcpSendTimeout=10, retries=5, useClientSubnet=true, order=1})
-- newServer({address="192.168.1.3:5356", name="dns3", pool="recursor", checkType="A", checkName="b.root-servers.net.", mustResolve=true, tcpRecvTimeout=10, tcpSendTimeout=10, retries=5, useClientSubnet=true, order=2})
--
-- Please report any bugs on GitHub.

function dump(o)
  if type(o) == 'table' then
     local s = '{ '
     for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. dump(v) .. ','
     end
     return s .. '} '
  else
     return tostring(o)
  end
end

function orderedwrandom(servers, dq)

	-- If there is only one or 0 servers in the table, return it to stop further processing
	if (#servers == 0 or #servers == 1) then
		return servers
	end

	-- Create server list table
	local serverlist = {}

	-- Loop over each server for the pool
	local i = 1
	while servers[i] do

		-- We only care if the server is currently up
		if (servers[i].upStatus == true) then

			-- Retrieve the order for the server
			local order = servers[i].order

			-- Create table for this order if not existing
			if type(serverlist[order]) ~= "table" then
				serverlist[order] = {}
			end

			-- Insert this server to the ordered table
			table.insert(serverlist[order], servers[i])

		end

	-- Increment counter for next loop
	i=i+1

	end

	-- Get the lowest key in the table so that we use the lowest ordered server(s)
  local lowest = nil
	for k,v in pairs (serverlist) do
		if lowest == nil then
			lowest = k
		else
			if k < lowest then
				lowest = k
			end
		end
	end

	-- Double check the server list has a value/is defined. I don't think this should
	-- ever happen, but you can't be too safe. If it has no value, then return the server
	-- list.
	if serverlist[lowest] == nil then
		return wrandom.policy(servers, dq)
	end

	-- Return the lowest ordered server list to the leastOutstanding function
	return wrandom.policy(serverlist[lowest], dq)

end
