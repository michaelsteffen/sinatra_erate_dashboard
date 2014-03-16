sinatra_erate_dashboard
=======================

Mark, Allison, Anne, any others -- 

This README assumes you're just getting started with the various frameworks used to build this little app.  If that's not right, you can skip most of it.  If you are just beginning, welcome and enjoy.  Once you get over the initial learning curve, there's really not much to it.  This kind of lightweight coding is a hobby of mine.  I hope you enjoy it as I do. 

The app is built with Sinatra (a framework for web apps using the Ruby programming language) & ActiveRecord (a very robust database inteface for Ruby), plus a fair bit of raw SQL for the dashboard queries.  The front end uses Twitter Bootstrap, a web front end framework placed in the public domain by the good folks at Twitter, along with some very minimal custom css styling.  The basic app structure is a "Model-View-Presenter" approach, which is a derivative of the usual "Model-View-Controller" framework.  I've deployed it on Heroku, a web app platform and hosting service, using the straight out-of-the-box configuration.  Googling around a little on these topics may help you make more sense of the code.

The simplest way to get a sense of the app is probably as follows:

- Start in the /db/migrate directory.  The files there are used by a standard utility called Rake (= "Ruby make") to build the backend Postgres database.  Even without knowing how rake works, they should give you a sense of the table structure.

- Next, look at /app.rb.  That's the main web app file, which consists of a series of "routes" -- basically, the URLs through which the app can be accessed and the different things they do.  Again, even without knowing any Ruby, that should give you the overview of the app.

- Then take a look at the files in /presenters/.  These are the Ruby modules that build the Form 471 and Item 24 dashboards, including the underlying SQL. 

The master branch should reflect what is deployed on Heroku, and hopefully more or less works.  I'm also working on a feature branch that reflects the latest suggestions from Mark, Lisa, and Mike -- and which may or may not actually work at any given moment.

Take a look at [this tutorial](http://ruby.railstutorial.org/) if you want help setting Ruby up on your mac.  The tutorial is for Rails, another Ruby-based web app framework that is a cousin of Sinatra, so it isn't 100% applicable, but the basic Ruby set-up should be the same, and many of the concepts are applicable.  

Finally, a word on editing: the way github private repos work, you now have full access to this repo. This allows you to directly commit to branches or master.  But I think it will work best if instead you fork your own branch before making changes and then submit pull requests to incorporate them back into master.  Your forked copies will automatically be made private (you don't have to pay to upgrade your account).

Enjoy!

Michael
