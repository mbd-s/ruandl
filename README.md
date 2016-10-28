**Ruandl** is a Ruby CLI that interacts with the Quandl API. It takes inputs for ticker symbols (e.g., "JCP") and dates (e.g., "2016-09-27" or "last week"). It then calculates the stock's performance over the given range, and tweets it from a custom Twitter bot (I used [@quandlbot](https://twitter.com/quandlbot)).

####Configuration

First, clone the repo, cd into the directory and run `bundle install`.

You'll need to [get an API key from Quandl](https://www.quandl.com/docs/api), which is quick and free.

You'll also need to [register your own Twitter app](https://apps.twitter.com/).

Add an .env file that looks something like this, replacing the placeholders with your own keys:

```
export QUANDL_API_KEY="YOUR_QUANDL_API_KEY"

export TWITTER_CONSUMER_KEY="YOUR_TWITTER_CONSUMER_KEY"
export TWITTER_CONSUMER_SECRET="YOUR_TWITTER_CONSUMER_SECRET"
export TWITTER_ACCESS_TOKEN="YOUR_TWITTER_ACCESS_TOKEN"
export TWITTER_ACCESS_TOKEN_SECRET="YOUR_TWITTER_ACCESS_TOKEN_SECRET"
```

Finally, run the program with `ruby ruandl.rb`.
