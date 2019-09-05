class SQApp < Sinatra::Base

    register Sinatra::ConfigFile

    config_file './config/config.yml'

    use Rack::Auth::Basic,"Protected Area" do |username, password|
      @@auth_user = User.find_by(username: username).authenticate(password)
    end

    before do
        content_type :xml
    end
        
    #ROUTES

    #Load greeting
    get '/' do
      '<?xml version="1.0" encoding="UTF-8"?>
<xml>
  <message>Welcome to user market API!</message>
</xml>'
    end
    
    #Get user info
    get '/users/:username' do
      user = User.select("id, username, level").find_by(username: params[:username])
      if user.present?
        user.to_xml
      else
        status 404
      end
    end

    #Get user market
    get '/users/:username/items' do
      user = User.find_by(username: params[:username])
      if !user.present?
        status 404
      else 
        lot = Lot.select("id, user_id, item_id, amount, price").where(user_id: user.id)
        if !lot.present?
          '<?xml version="1.0" encoding="UTF-8"?>
<xml>
  <message>User has no items on the market.</message>
</xml>'
        else
          lot.to_xml
        end
      end
    end

    #Get public market
    get '/market' do
      lot = Lot.filter(params).where(public: true)
      if lot.present?
        lot.to_xml
      else
        status 404
      end
    end

    #Buy item
    put '/users/:username/items/:itemname' do
      user = User.find_by(username: params[:username])
      item = Item.find_by(name: params[:itemname])
      if user.present? && item.present?
        lot = Lot.find_by(user_id: user.id, item_id: item.id)
        if lot.present? || @@auth_user.id != lot.user_id
          if params.has_key?("amount") || params[:amount].to_i <= 0 || params[:amount].to_i > lot.amount
            total_price = params[:amount].to_i * lot.price
            if total_price < @@auth_user.balance
              @@auth_user.update_column("balance", @@auth_user.balance - total_price)
              inventory = Inventory.find_by(user_id: @@auth_user.id, item_id: lot.item_id)
              if inventory.present?
                inventory.update(amount: inventory.amount + params[:amount].to_i)
              else
                Inventory.create(user_id: @@auth_user.id, item_id: lot.item_id, amount: params[:amount].to_i)
              end
              user.update_column("balance", user.balance + total_price)
              if params[:amount].to_i == lot.amount
                lot.destroy
              else
                lot.update(amount: lot.amount - params[:amount].to_i)
              end
              status 204
            else
              status 402
            end
          else
            status 403
          end
        else
          status 404
        end
      else
        status 404
      end
    end

    #Get your profile info
    get '/dashboard' do
      @@auth_user.to_xml
    end

    #Get your items
    get '/dashboard/inventory' do
      inventory = Inventory.where(user_id: @@auth_user.id)
      if inventory.present?
        inventory.to_xml
      else
        '<?xml version="1.0" encoding="UTF-8"?>
<xml>
  <message>You have no items on the market.</message>
</xml>'
      end
    end

    #Add lot
    post '/dashboard/inventory/:id' do
      inventory = Inventory.find_by(id: params[:id].to_i)
      if !inventory.present?
        status 404
      elsif params[:amount].to_i > inventory.amount || params[:amount].to_i < 1 || params[:amount].to_i > 10 || !params.has_key?("price") || !params.has_key?("amount")
        status 403
      else
        lot = Lot.new(user_id: inventory.user_id, item_id: inventory.item_id, amount: params[:amount].to_i, price: params[:price].to_i, public: false)
        if lot.invalid?
          status 403
        else
          lot.save
          if inventory.amount -= lot.amount != 0
            inventory.update_column("amount", inventory.amount - lot.amount)
          else
            inventory.destroy
          staus 201
          end
        end 
      end   
    end

    #Get your lots
    get '/dashboard/lots' do
      lot = Lot.where(user_id: @@auth_user.id)
      if lot.present?
        lot.to_xml
      else
        status 404
      end
    end

    #Make lot public
    patch '/dashboard/lots/:id' do
      if Lot.where(public: true).count < settings.max_market_rec
        lot = Lot.find_by(id: params[:id].to_i)
        if !lot.present? 
          status 404  
        elsif lot.user_id != @@auth_user.id && lot.public = true
          status 403 
        elsif @@auth_user.balance < 100
          status 402 
        else
          @@auth_user.update_column("balance", @@auth_user.balance -= 100)
          lot.update(public: true)
          status 204
        end
      else 
        status 403
      end
    end  

    #Remove lot from the market
    delete '/dashboard/lots/:id' do
      lot = Lot.find_by(id: params[:id])
      if !lot.present?
        status 404
      elsif lot.user_id != @@auth_user.id
        status 403
      else
        inventory = Inventory.find_by(user_id: lot.user_id, item_id: lot.item_id)
        if !inventory.present?
          Inventory.create(user_id: lot.user_id, item_id: lot.item_id, amount: lot.amount)
        else
          inventory.update_column("amount", inventory.amount + lot.amount)
        end
        lot.destroy
        status 204
      end  
    end
end