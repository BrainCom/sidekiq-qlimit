# sidekiq-qlimit
Per Queue Limit for Sidekiq

Add to your Gemfile
-------------------
Note: We're not yet released, so we're simply tracking the master branch for now.  

If using Rails 5
```
gem 'sinatra', :require => nil, github: 'sinatra/sinatra', branch: 'master'
gem 'sidekiq'
gem 'sidekiq-qlimit', github: 'BrainCom/sidekiq-qlimit', branch: 'master'
```

If using Rails 4
```
gem 'sidekiq'
gem 'sidekiq-qlimit', github: 'BrainCom/sidekiq-qlimit', branch: 'master'
```

If trying to update sidekiq-qlimit gem to the latest version on github/master
```
$ bundle update sidekiq-qlimit
```


Initialize
-------------
config/sidekiq-qlimit.rb
```
require "sidekiq/qlimit"
Sidekiq::Qlimit.setup!
```


Configure
-------------
config/sidekiq.yml
```
---
:concurrency: 5
:pidfile: tmp/pids/sidekiq.pid
:queues:
  - unlimited
  - limited
:qlimit:
  - limited: 2
  - fake: 3
```

Run
---
* rails c
```
10.times { LimitedWorker.perform_async }
10.times { UnlimitedWorker.perform_async }
```
* rails s
* bundle exec sidekiq
* http://localhost:3000/sidekiq

