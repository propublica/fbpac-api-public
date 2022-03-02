# FBPAC API

This repository is no longer maintained and exists for archival purposes only.

For a more recent project on this topic, see
[Ad Observer](https://adobserver.org).

<details><summary>See archival README information.</summary>

A Ruby API for the Facebook Political Ad Collector site.

First, this will mirror _most_ of the admin-facing functions of the Rust API, then adding new stuff more nimbly to respond to what we want to present to partners and readers.

It's structured to be a drop-in replacement for some pieces of the Rust API... and to run _alongside_ it. (The Rust API will continue to catch the ads and to serve static assets.)

# Installation Instructions

0. You should have the [Rust app](https://github.com/propublica/facebook-political-ads) installed and running.
1. Clone this repo. 
2. `bundle install` in the root of this repo.
3. Run `rake db:migrate` just to be sure we have all the changes we need. (Unless you have a post-4/4/2018 DB dump).
4. `bundle exec rails s`
5. Visit http://localhost:3000/fbpac-api/ads -- you should see a big pile of JSON.
6. Visit http://localhost:3000/fbpac-api/ads/by_advertisers -- you should see a log in page. 
7. Create a user for yourself, locally, by running this in `rails c`. `User.create!({:email => "you@propublica.org", :password => "111111", :password_confirmation => "111111" })`.
8. Try http://localhost:3000/fbpac-api/ads/by_advertisers again, log in, then you should see more JSON.

### Testing / comparison with the Rust API

`rake test` runs the tests. Be sure to write new ones for new features!


### How to create new users:

Unlike the Rust API, we have real user accounts with a unique password per account. When a partner signs up, log into the production console with `RAILS_ENV=production rails c` and create them a user account with `User.create!({:email => "you@propublica.org", :password => "111111", :password_confirmation => "111111" })`. Then they should be good to go.

</details>
