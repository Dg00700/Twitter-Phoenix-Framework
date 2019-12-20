defmodule Twitter do

  def start() do
      GenServer.start_link(__MODULE__, [], name: :twitter)
  end

  def init(state) do
      Registry.start_link(keys: :unique, name: :registry)
      Server.start()
      {:ok, state}
  end

  def simulate(num_user, num_msg) do
      users_list = Enum.to_list(1..num_user) |> Enum.map(fn(user)-> "User-"<>Integer.to_string(user) end)
      Enum.each(users_list, fn(user_id) ->
          {:ok, pid} = Client.start(user_id)
          GenServer.call(pid, {:create_account, user_id,user_id,user_id})
      end)

      create_follower_list(num_user,users_list)
      Enum.each(1..num_msg, fn(count)->
          start_sending_message(users_list,num_user)
      end)
    Process.sleep(1000)
      users_list
  end

  def create_follower_list(num_user,users_list) do
    temp_users_list = users_list
    pc1 = floor((num_user/100)*5)
    pc2 = floor((num_user/100)*30)
    pc3 = floor((num_user/100)*50)
    pc4 = floor((num_user/100)*15)
    c1 = Enum.take_random(temp_users_list,pc1)
    temp_users_list = temp_users_list -- c1
    c2 = Enum.take_random(temp_users_list,pc2)
    temp_users_list = temp_users_list -- c2
    c3 = Enum.take_random(temp_users_list,pc3)
    temp_users_list = temp_users_list -- c3
    c4 = Enum.take_random(temp_users_list,pc4)

    generate_follower_list(users_list, c1,floor(num_user*0.7)..floor(num_user*0.9))
    generate_follower_list(users_list, c2,floor(num_user*0.5)..floor(num_user*0.7))
    generate_follower_list(users_list, c3,floor(num_user*0.2)..floor(num_user*0.5))
    generate_follower_list(users_list, c4,floor(num_user*0.05)..floor(num_user*0.2))

  end


  def zipf(n, alpha \\ 1) do
      c = 1/Enum.reduce(1..n, 0, fn (x, acc) ->
          _acc = acc + 1/:math.pow(x,alpha) end)
      Enum.reduce(1..n, %{}, fn (x, acc) ->
          _acc = Map.put(acc, x, c/:math.pow(x,alpha)) end)
end

def generate_follower_list(users_list, category_user_list, followers_number) do
    Enum.each(category_user_list, fn(user_id) ->
        no_of_followers = Enum.random(followers_number)
        followers_list = Enum.take_random(users_list--[user_id], no_of_followers)
        Enum.each(followers_list, fn(follower_id) ->
            GenServer.cast(get_pid(user_id),{:follow, follower_id})
        end)
    end)
end


  def start_sending_message(users_list,num_user) do
      message_list= ["booyaaaaaaaaa.", "Merry christmas", "Where do you wanno go?" ,"Scooby Dooby doo.","Imma so hungry.","How you doing?","Welcome to the jungle.","Take me home to the paradise city."]
      hashtag_list=["#husky","#boo","#elixi","#final","#pizza","#UF","#GoGators","#Nirvana","#GunnRoses","#Happy"]
      Enum.each(users_list, fn(user_id)->
          message = Enum.random(message_list)
                  |> String.replace("#",Enum.random(hashtag_list))
                  |> String.replace("@","@"<>Enum.random(users_list--[user_id]))
          GenServer.cast(get_pid(user_id),{:tweet_msg,message})
      end)
  end


  def get_pid(user_handle) do
      case Registry.lookup(:registry, user_handle) do
          [{pid, _}] -> pid
          [] -> nil
      end
  end

 end
