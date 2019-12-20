// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
 import socket from "./socket"
let userchannel;
let init_fun;
window.login = function(event){
    var username = document.getElementById("username")
    var password = document.getElementById("password")
    if(username.length!=0 && password.length!=0){
        userchannel = socket.channel(`twitter:${username.value}`, {});
        userchannel.join()
            .receive("ok", resp => { console.log("Joined successfully", resp) })
            .receive("error", resp => { console.log("Unable to join", resp) })
        userchannel.push('login', { 
            username: username.value,
            password: password.value
        });
        check_login(userchannel);
    }
    // window.location.href = "./home";
 }

 function check_login(userchannel){
    var username = document.getElementById("username")
    userchannel.on(`twitter:${username.value}:login_sucessfull`, function (payload) {
        console.log(payload);
        alert("logged In")
        window.location.href = "./home?username="+username.value;
    });

    userchannel.on(`twitter:${username.value}:login_failed`, function (payload) {
        alert("Invalid Username or Password. Please try again");
    });
}


window.register=function() 
{
    var username = document.getElementById("username")
    var password = document.getElementById("password")
    if(username.length!=0 && password.length!=0){
        userchannel = socket.channel(`twitter:${username.value}`, {});
        userchannel.join()
            .receive("ok", resp => { console.log("Joined successfully", resp) })
            .receive("error", resp => { console.log("Unable to join", resp) })
        userchannel.push('register', { 
            username: username.value,
            password: password.value
        });
       // check_register(userchannel);
    }
    // window.location.href = "./home";
 }
       
 
var url = new URL(window.location.href);
var username = url.searchParams.get("username");

if(username!=null){
    Initialize_Connection()
}

function Initialize_Connection() {
    var username_header = document.getElementById("username");
    username_header.innerText = username;
    userchannel = socket.channel(`twitter:${username}`, {});
    userchannel.join();
    get_follower();
    if(window.location.href.indexOf("home") > -1){
        get_tweets()
    }
}
 
window.tweet = function() { 
    let message = document.getElementById("tweetbox");
    if(message.value.length > 0){
        userchannel.push('tweet', { 
            message: message.value   
        });
        message.value = '';  
    }

    userchannel.on(`twitter:${username}:tweetsend`, function (payload) {
        alert("Tweet Send")
    });
    
}

window.getquery = function() { 
    let search = document.getElementById("searchbox");
    if(search.value.length > 0){
        if(search.value.includes("#")){
            userchannel.push('hashtag', { 
                searchquery: search.value   
            });
        }
        search.value = '';  
    }

    userchannel.on(`twitter:${username}:hashtagresult`, function (payload) {
        let ul = document.getElementById("result-list");
        ul.innerHTML = '';
        if(payload.result_list.length == 0){
            var li = document.createElement("li"); // create new list item DOM element
            li.innerHTML =  '<b> No Result Found</b>'; // set li contents
            ul.insertBefore(li, ul.childNodes[0]);     
        }else{
            for(var tweet in payload.result_list) {
                var li = document.createElement("li"); // create new list item DOM element
                li.innerHTML =  '<b>' + payload.result_list[tweet][0] + ': </b>' + payload.result_list[tweet][1];// set li contents
                ul.insertBefore(li, ul.childNodes[0]);     
            }
        }
    });
    
}

window.follow = function() { 
    let follow_id = document.getElementById("follow_id");
    if(follow_id.value.length > 0){
        userchannel.push('follow', { 
            follow_id: follow_id.value   
        });
        follow_id.value = '';  
    }

    userchannel.on(`twitter:${username}:follow_success`, function (payload) {
        alert("You are now following "+ payload.follow_id);
        get_follower();
    });
    
}
window.homepage = function() { 
    window.location.href = "./home?username="+username;
}

window.searchquery = function() { 
    window.location.href = "./searchquery?username="+username;
}


function get_tweets(){
    userchannel.push('get_tweets', {
        user: username
    });

    userchannel.on(`twitter:${username}:tweet_list`, function (payload) {
        let ul = document.getElementById("tweet-list");
        for(var tweet in payload.tweet_list) {
            var li = document.createElement("li"); 
            li.innerHTML =  '<b>' + payload.tweet_list[tweet][0] + ' : </b>' + payload.tweet_list[tweet][2]; // set li contents
        
            ul.insertBefore(li, ul.childNodes[0]);     
        }
    });
}





function get_follower(){
    userchannel.push('get_follower', {
        user: username
    });

    userchannel.on(`twitter:${username}:followers_list`, function (payload) {
        console.log(payload);
        let ul = document.getElementById("follower-list");
        ul.innerHTML = '';
        var followers_list = payload.followers_list.sort()
        for(var follower in followers_list) {
            let li = document.createElement("li"); // create new list item DOM element
            li.innerHTML =  payload.followers_list[follower]; // set li contents
            ul.appendChild(li);     
        }
    });
}



