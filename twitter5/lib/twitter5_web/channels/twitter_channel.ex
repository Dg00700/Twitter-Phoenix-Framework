defmodule Twitter5Web.TwitterChannel do
  use Twitter5Web, :channel

  def join("twitter:"<>username, payload, socket) do

    if authorized?(payload) do
      {:ok, %{channel: "twitter:#{username}"}, assign(socket, :user_id, username)}
    else
      {:error, %{reason: "unauthorized"}}
    end

  end

  def handle_in("login", payload, socket) do
    username = payload["username"]
    status = GenServer.call(:twitter_engine,{:login_user,payload["username"],payload["password"]})

    IO.inspect status, label: "status"
    if(status == :success) do
      broadcast!(socket, "twitter:#{username}:login_sucessfull",payload)
      IO.inspect "Logged IN"

    else
      broadcast!(socket, "twitter:#{username}:login_failed",payload)
    end

    {:noreply, socket}
  end

  def handle_in("register", payload, socket) do
    username = payload["username"]
    status = GenServer.call(:twitter_engine,{:register_user,payload["username"],payload["username"],payload["password"]})

    IO.inspect status, label: "status"
    if(status == :success) do
      broadcast!(socket, "twitter:#{username}:register_sucessfull",payload)

    else
      broadcast!(socket, "twitter:#{username}:register_failed",payload)
    end

    {:noreply, socket}
  end


  def handle_in("tweet", payload, socket) do
    user_id = socket.assigns[:user_id]
    GenServer.cast(:twitter_engine,{:tweet_message,payload["message"],user_id})
    broadcast!(socket, "twitter:#{user_id}:tweetsend",payload)
    {:noreply, socket}
  end

  def handle_in("get_follower", payload, socket) do
    user_id = socket.assigns[:user_id]
    followers_list = GenServer.call(:twitter_engine,{:get_followers_list,user_id})
    payload = %{:followers_list =>followers_list }
    broadcast!(socket, "twitter:#{user_id}:followers_list",payload)
    {:noreply, socket}
  end

  def handle_in("get_tweets", payload, socket) do
    user_id = socket.assigns[:user_id]
    tweet_list = GenServer.call(:twitter_engine,{:get_tweet_list,user_id})
    payload = %{:tweet_list =>tweet_list }
    broadcast!(socket, "twitter:#{user_id}:tweet_list",payload)
    {:noreply, socket}
  end



  def handle_in("hashtag", payload, socket) do
    user_id = socket.assigns[:user_id]
    result_list = GenServer.call(:twitter_engine,{:get_messages_with_hashtags,payload["searchquery"]})
    payload = %{:result_list =>result_list }
    broadcast!(socket, "twitter:#{user_id}:hashtagresult",payload)
    {:noreply, socket}
  end

  def handle_in("follow", payload, socket) do
    user_id = socket.assigns[:user_id]
    result_list = GenServer.cast(:twitter_engine,{:user_followers,user_id, payload["follow_id"]})
    broadcast!(socket, "twitter:#{user_id}:follow_success",payload)
    {:noreply, socket}
  end


  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (twitter:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  def distributeTweet(user_id, tweetId, tweet, followers_list) do
    #IO.inspect user_id<>" "<>tweetId<>" "<>tweet<>" "<>followers_list, label: "sending"
    payload = %{:tweet_list => [[user_id, tweetId, tweet]]}
    Enum.each(followers_list, fn(follower) ->
      Twitter5Web.Endpoint.broadcast!("twitter:#{follower}", "twitter:#{follower}:tweet_list", payload)
    end)
  end
end
