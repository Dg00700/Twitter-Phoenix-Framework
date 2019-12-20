


defmodule Server do


  def start() do
      GenServer.start_link(__MODULE__, [], name: :twitter_engine)
  end

  def init(state) do
      :ets.new(:user_details, [:set, :public, :named_table])
      :ets.new(:user_tweets, [:set, :public, :named_table])
      :ets.new(:newsfeed, [:set, :public, :named_table])
      :ets.new(:active_users, [:set, :public, :named_table])
     :ets.new(:undelivered_tweets, [:set, :public, :named_table])
      :ets.new(:follower_list, [:set, :public, :named_table])
      :ets.new(:following_list, [:set, :public, :named_table])
      :ets.new(:mentions, [:set, :public, :named_table])
      :ets.new(:hashtags, [:set, :public, :named_table])
      {:ok, state}
  end

  def handle_call({:register_user,user_handle, user_name, password}, _from , state) do
      if (!checkIfUserExists(user_handle)) do
          :ets.insert(:user_details,{user_handle,user_name,password})
          :ets.insert(:active_users,{user_handle, true})
          {:reply,:ok,state}
      else
          {:reply,"User Handle #{user_handle} already exists",state}
      end
  end

  def handle_call({:login_user,received_user_id, received_password}, _from , state) do
      userdata = retreive_d(:user_details, received_user_id)
      if(userdata!=[]) do
        [user_id,user_name,actual_password]=userdata
        if(actual_password == received_password) do
            #Login Successful
            IO.puts "Login Successfull for "<>user_id
            :ets.insert(:active_users,{user_id, true})
            pendingTweets = retreive_d(:undelivered_tweets, user_id)
            if(pendingTweets!=[]) do
                Enum.each(pendingTweets, fn(tweet_data)->
                    from_user_id = Enum.at(tweet_data,0)
                    tweet_id = Enum.at(tweet_data,1)
                    tweet = retreive_d(:user_tweets, from_user_id)
                    t_newsfeed(received_user_id,from_user_id,tweet_id)
                    GenServer.cast(Twitter.get_pid(user_id),{:news_feed, from_user_id,tweet_id, tweet[tweet_id]})
                end)
            end

            :ets.delete(:undelivered_tweets, user_id)
            {:reply, :success, state}
        else
            IO.puts "Login Failed. Invalid Password"
            {:reply, :failed , state}
        end

        else
            IO.puts "No User exist"
            {:reply, :not_exist, state}
        end
    end

  def handle_call({:logout_user,user_id}, _from , state) do
      IO.puts "Logout Successfull for "<>user_id
      :ets.insert(:active_users,{user_id, false})
      {:reply, :ok , state}
  end

  def checkIfUserExists(user_handle) do
      case :ets.lookup(:user_details,user_handle) do
          [{user_handle,_, _}] -> true
          [] -> false
      end
  end

  def handle_cast({:setFollowers,users,follower},state) do
    # IO.puts "User is #{users}, Followers are #{follower}"
    :ets.insert(:followers,{users,follower})
    list = :ets.lookup(:followers,users)
    IO.inspect list, label: "followers list"
{:noreply,state}
end
def handle_cast({:add_followee_list,user1, user2},state) do

    :ets.insert(:followee, {user1, user2})
{:noreply,state}
end

  def handle_call({:delete_user,user_handle}, _from , state) do
      if (checkIfUserExists(user_handle)) do
          :ets.delete(:user_tweets, user_handle)
          :ets.delete(:newsfeed, user_handle)
          :ets.delete(:active_users, user_handle)
          :ets.delete(:undelivered_tweets, user_handle)
          :ets.delete(:follower_list, user_handle)
          IO.puts "User Deleted"
          {:reply,:ok,state}
      else
          {:reply,"User #{user_handle} does not exist",state}
      end
  end

  def handle_cast({:user_followers, follower_id,user_id}, state) do
      #update followers table
      current_follower_list = retreive_d(:follower_list, user_id)
      current_follower_list = current_follower_list ++ [follower_id]
      :ets.insert(:follower_list,{user_id,current_follower_list})

      #update following table
      current_following_list = retreive_d(:following_list, follower_id)
      current_following_list = current_following_list ++ [user_id]
      :ets.insert(:following_list,{follower_id,current_following_list})

      {:noreply, state}
  end

  def handle_cast({:tweet_message, tweet, from_user_id}, state) do
      #add the tweet in the tweet list
      tweet_id = tweet_sent(tweet,from_user_id)
      #parse the tweet for hashtags
      if(String.contains?(tweet,"#")) do
          hashtag_see(from_user_id, tweet_id, tweet)
      end
      #send the tweet to all the followers and to the mentions
      sender_list = if(String.contains?(tweet,"@")) do
          listOfUserMentions = mention_see(from_user_id, tweet_id, tweet)
          Enum.uniq(retreive_d(:follower_list, from_user_id) ++ (listOfUserMentions |> Enum.map(fn(x)->  String.replace(x,"@","")end)))
      else
          retreive_d(:follower_list, from_user_id)
      end

      Enum.each(sender_list, fn(follower_id) ->
          isActive = retreive_d(:active_users, follower_id)
          if (isActive) do
              t_newsfeed(follower_id,from_user_id,tweet_id)
              GenServer.cast(Twitter.get_pid(follower_id),{:news_feed, from_user_id,tweet_id, tweet})
          else
              add_tweets(follower_id, from_user_id, tweet_id)
          end
      end)
      Twitter5Web.TwitterChannel.distributeTweet(from_user_id, tweet_id, tweet, sender_list)
      {:noreply, state}
  end
  def add_tweets(for_user_id, from_user_id, tweet_id) do
      #IO.puts "Putting in Pending List message for #{for_user_id} from #{from_user_id} and tweetid #{tweet_id}"
      mentionsList = retreive_d(:undelivered_tweets, for_user_id)
      mentionsList =  mentionsList ++ [[from_user_id,tweet_id]]
      :ets.insert(:undelivered_tweets,{for_user_id,mentionsList})
  end

  def handle_call({:get_followers_list, user_id}, _from, state) do
    databaseValue = retreive_d(:follower_list, user_id)
    {:reply, databaseValue, state}
end

  def tweet_sent(tweet, user_id) do
      tweet_map = retreive_d(:user_tweets,user_id)
      if(tweet_map == []) do
          tweet_map = %{length(tweet_map)=> tweet}
          :ets.insert(:user_tweets,{user_id,tweet_map})
      else
          tweet_map = Map.put(tweet_map,map_size(tweet_map), tweet)
          :ets.insert(:user_tweets,{user_id,tweet_map})
      end
      map_size(retreive_d(:user_tweets,user_id))-1
  end

  def t_newsfeed(user_id, from_user_id, tweet_id) do
      newsFeedList = retreive_d(:newsfeed, user_id)
      newsFeedList =  newsFeedList ++ [[from_user_id,tweet_id]]
      :ets.insert(:newsfeed,{user_id,newsFeedList})
  end

  def hashtag_see(user_id, tweet_id, tweet) do
      listOfHashTags = Regex.scan(~r(\B#[a-zA-Z1-9_]+\b), tweet)
      listOfHashTags = List.flatten(listOfHashTags)
      Enum.each(listOfHashTags, fn(hashtag)->
          hashtagList = retreive_d(:hashtags, hashtag)
          hashtagList =  hashtagList ++ [[user_id,tweet_id]]
          :ets.insert(:hashtags,{hashtag,hashtagList})
      end)
  end

  def mention_see(user_id, tweet_id, tweet) do
      listOfUserMentions = Regex.scan(~r(\B@[a-zA-Z1-9-_]+\b), tweet)
      listOfUserMentions = List.flatten(listOfUserMentions)
      Enum.each(listOfUserMentions, fn(mention_id)->
          mention_id = String.replace(mention_id, "@", "")
          mentionsList = retreive_d(:mentions, mention_id)
          mentionsList =  mentionsList ++ [[user_id,tweet_id]]
          :ets.insert(:mentions,{mention_id,mentionsList})
      end)
      listOfUserMentions
  end


  def handle_call({:get_messages_with_hashtags, search_hashtag}, _from, state) do
      hashtag_message_list = retreive_d(:hashtags, search_hashtag)
      message_list = Enum.reduce(hashtag_message_list, [], fn(message_data, acc) ->
          from_user = Enum.at(message_data,0)
          tweet = retreive_d(:user_tweets, Enum.at(message_data,0))
          acc = acc ++ [[from_user, tweet[Enum.at(message_data,1)]]]
      end)
      {:reply, message_list, state}
  end

  def handle_call({:get_messages_with_mentions, search_mention}, _from, state) do
      mentions_message_list = retreive_d(:mentions, search_mention)
      message_list = Enum.reduce(mentions_message_list, [], fn(message_data, acc) ->
          from_user = Enum.at(message_data,0)
          tweet = retreive_d(:user_tweets, Enum.at(message_data,0))
          acc = acc ++ [[from_user, tweet[Enum.at(message_data,1)]]]
      end)
      {:reply, message_list, state}
  end

  def handle_call({:get_tweet_list, user_id}, _from, state) do
    databaseValue = retreive_d(:newsfeed, user_id)
    if(databaseValue != []) do
        tweet_list = Enum.reduce(databaseValue, [], fn(x, acc) ->
            username =  Enum.at(x,0)
            tweetid = Enum.at(x,1)
            tweet = retreive_d(:user_tweets, username)
            acc = acc ++ [[username, tweetid, tweet[tweetid]]]
        end);
        {:reply, tweet_list, state}
    end
end


  def retreive_d(table_name, user_id) do
      case :ets.lookup(table_name,user_id) do
          [{user_handle,user_name, password}] -> [user_handle, user_name,password]
          [{user_id,data}] -> data
          [] -> []
      end
  end

  def handle_cast({:retweet_message, retweet_msg, user_id}, state) do
    sender_list = retreive_d(:follower_list, user_id)

    tweet_id = tweet_sent(retweet_msg,user_id)
    Enum.each(sender_list, fn(follower_id) ->
        isActive = retreive_d(:active_users, follower_id)
        if (isActive) do
            t_newsfeed(follower_id,user_id,tweet_id)
            GenServer.cast(Twitter.get_pid(follower_id),{:retweet_message,user_id,tweet_id, retweet_msg})
        else
            add_tweets(follower_id, user_id, tweet_id)
        end
    end)
    {:noreply, state}
end

def handle_cast({:retweet_serverr,user,numCl},state) do

  tweetlist= :ets.lookup(:user_tweets,user)
  size=Enum.count(tweetlist)
  IO.puts "#{size} #{inspect tweetlist}"
  if(size<0) do
      index=Enum.random(0..size-1)
      {_,_,tweet}=Enum.at(tweetlist,index)
      retweet="RETWEET:"<>tweet
      :ets.insert(:user_tweets,{user,retweet})
  end

{:noreply,state}
end
def handle_cast({:showingTweet,user},state) do
    #IO.puts "handlecast showtweet**********************************"
     list=:ets.lookup(:user_tweets,user)

     followee_list=:ets.lookup(:followee,user)
     size=Enum.count(followee_list)
     sublist=[]
     sublist= for i<- 0..size-1 do
        {_,followee}=Enum.at(followee_list,i)
        #IO.inspect followee
        sublist=[:ets.lookup(:user_tweets,followee)|sublist]
        sublist
     end
     sender=String.to_atom(user)
     GenServer.cast(sender,{:display,user,list,sublist})
    # list=:ets.lookup(:user_tweets,"User2")
    #  IO.puts "#{inspect list}"
    {:noreply,state}
   end
end
