get '/steam/banned' do
    output = @header
    
    users = DB[:users].all
    unique_steam = users.uniq{ |u| u[:steam64] }
    unique_users = users.uniq{ |u| u[:server_id] }
    results = Array.new()
    unique_steam.each { |steam|
        count = unique_users.select{ |u| u[:steam64] == steam[:steam64] }.count
        data = {:steam64 => steam[:steam64], :count => count}
        results.push data
    }
    output << partial(:steam_ban, :locals => {
        ban_list: results
    })
    
    output << partial(:footer)
end