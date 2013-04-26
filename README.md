Artsy Feathers
==============

Artsy Feathers is a set of examples that combine [Artsy Ruby client](https://github.com/artsy/artsy-ruby-client) and the [Twitter Ruby client](https://github.com/sferik/twitter) to tweet artworks and shows.

Please note that Artsy currently doesn't have a public API program. API keys are required to run this sample. Email engineering@artsy.net and we'll notify you when this is available.

Running
-------

* [Register an application on Twitter](https://dev.twitter.com/apps/new). Edit its settings and set it to read/write.
* Note the Twitter consumer key, secret, OAuth token and token secret.
* Note the Artsy application client id and client secret.

```
TWITTER_CONSUMER_KEY=...
TWITTER_CONSUMER_SECRET=...
TWITTER_OAUTH_TOKEN=...
TWITTER_OAUTH_TOKEN_SECRET=...
ARTSY_API_CLIENT_ID=...
ARTSY_API_CLIENT_SECRET=...
bundle exec ruby examples/tweet_new_shows.rb
```

Examples
--------

* [Tweet a New Artwork](examples/tweet_new_artwork.rb)
* [Tweet New Shows](examples/tweet_new_shows.rb)

Contributing
------------

Fork the project. Make your feature addition or bug fix with tests. Send a pull request. Bonus points for topic branches.

Copyright and License
---------------------

MIT License, see [LICENSE](http://github.com/dblock/mongoid-scroll/raw/master/LICENSE.md) for details.

(c) 2013 [Daniel Doubrovkine](http://github.com/dblock), [Artsy Inc.](http://artsy.net)
