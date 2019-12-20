defmodule Client do
  def start(user_handle) do
      GenServer.start_link(__MODULE__, [], name: {:via, Registry, {:registry, user_handle}})
  end

  def init(state) do
      {:ok, state}
  end

  def registration(user_id, user_name,password) do
    GenServer.call(:twitter_engine, {:register_user, user_id, user_name,password} )
end


def follower(user_id, user_name,password,follower_id) do
  {:ok, pid} = Client.start(user_id)
  GenServer.call(pid, {:create_account, user_id,user_name,password})
  GenServer.cast(pid,{:follow, follower_id})
end

def send_tweets(user_id, message) do
GenServer.cast(Twitter.get_pid(user_id),{:tweet_msg,message})
end

def retweets(user_id) do
message_tweet = GenServer.call(Twitter.get_pid(user_id),{:retweet})
message_tweet
end

def logout(user_id) do
message_tweet = GenServer.call(Twitter.get_pid(user_id),{:logout})
end

def login(user_id,password) do
message_tweet = GenServer.call(Twitter.get_pid(user_id),{:login, user_id,password})
end



  def handle_call({:create_account, user_id, user_name, password}, _from, news_feed) do
      GenServer.call(:twitter_engine, {:register_user, user_id, user_name,password})
      {:reply, :ok, news_feed}
  end

  def handle_call({:delete_account, user_id}, _from, news_feed) do
      GenServer.call(:twitter_engine, {:delete_user, user_id})
      GenServer.call(:twitter_engine, {:logout_user, user_id})
      {:reply, :ok, news_feed}
  end

  def handle_call({:login, user_id, password}, _from, news_feed) do
      GenServer.call(:twitter_engine, {:login_user, user_id,password})
      {:reply, :ok, news_feed}
  end

  def handle_call({:logout}, _from, news_feed) do
      [my_user_id] = Registry.keys(:registry, self())
      GenServer.call(:twitter_engine, {:logout_user, my_user_id})
      {:reply, :ok, news_feed}
  end

  def handle_cast({:follow, follow_id}, news_feed) do
      [my_user_id] = Registry.keys(:registry, self())
      GenServer.cast(:twitter_engine, {:user_followers, my_user_id, follow_id})
      {:noreply, news_feed}
  end

  def handle_cast({:tweet_msg,message},news_feed)do
      [my_user_id] = Registry.keys(:registry, self())
      GenServer.cast(:twitter_engine, {:tweet_message,message, my_user_id})
      {:noreply, news_feed}
  end

  def handle_cast({:news_feed,from_user_id,tweet_id, message},news_feed)do
      [my_user_id] = Registry.keys(:registry, self())
      #IO.puts "#{my_user_id} : Message received from #{from_user_id}: - #{message}"
      news_feed = news_feed ++ [[from_user_id, tweet_id,message]]
      {:noreply, news_feed}
  end

  def handle_cast({:retweet_message,from_user_id,tweet_id, message},news_feed) do
      [my_user_id] = Registry.keys(:registry, self())
      retweeted_message_from = from_user_id
      news_feed = news_feed ++ [[from_user_id, tweet_id,message]]
      {:noreply, news_feed}
  end

  def handle_call({:retweet},_from,news_feed)do
      [my_user_id] = Registry.keys(:registry, self())
      tweet_data =
      if(news_feed!=[]) do
          Enum.random(news_feed)
      else
          []
      end
      retweet_msg = "Retweet:"<>Enum.at(tweet_data,0)<>":tweet:"<>Enum.at(tweet_data,2)
      #IO.inspect retweet_msg, label: "random retweeting message from "
      if(tweet_data!=[]) do
          GenServer.cast(:twitter_engine, {:retweet_message,retweet_msg, my_user_id})
      end
      {:reply,retweet_msg, news_feed}
  end

  def handle_call({:query_hashtags},_from, news_feed) do
      hashtag = Enum.random(["#husky","#boo","#elixi","#final","#pizza","#UF","#GoGators","#Nirvana","#GunnRoses","#Happy"])
      hashtag_messages = GenServer.call(:twitter_engine, {:get_messages_with_hashtags, hashtag})
      if(hashtag_messages!=[]) do
          IO.inspect hashtag_messages, label: "\n\nMessage Found for "<>hashtag<>"\n"
      else
          IO.puts "No Message found for "<>hashtag
      end
      {:reply,:ok, news_feed}
  end

  def handle_call({:query_mymentions},_from, news_feed) do
      [my_user_id] = Registry.keys(:registry, self())
      mentioned_messages = GenServer.call(:twitter_engine, {:get_messages_with_mentions, my_user_id})
      if(mentioned_messages!=[]) do
          IO.inspect mentioned_messages, label: "\n\nMessage Found for Mention ID - "<>my_user_id<>"\n"
      else
          IO.puts "No Message found for Mention ID - "<>my_user_id
      end
      {:reply,:ok, news_feed}
  end
  def handle_cast({:display_query,user,hashtag_list},state) do

    :timer.sleep(1000)

    IO.puts "#{user} Query Notification"
    IO.puts " "
    IO.puts "Results with the hashtag: #{inspect hashtag_list}"
    IO.puts " "

       {:noreply,state}
   end

   def handle_cast({:display_u,user,list,sublist},state) do

    :timer.sleep(1000)
    IO.puts "#{user} Notification"
    IO.puts " "
    IO.puts "Personal Tweets: #{inspect list}"
    IO.puts " "
    IO.puts "Received Tweets: #{inspect sublist}"
       {:noreply,state}
   end

 end
