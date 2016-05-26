# sidekiq-qlimit
Per Queue Limit for Sidekiq

Add to your Gemfile
-------------------
If using Rails 5 - Use sinatra master branch
```
gem 'sinatra', :require => nil, github: 'sinatra/sinatra', branch: 'master'
gem 'sidekiq'
```

If using Rails 4 - Make sure you at least have sidekiq
```
gem 'sidekiq'
```

Of course, add sidekiq-qlimit
```
gem 'sidekiq-qlimit', '~> 0'
```

Bleeding Edge
-------------------
If you want to ride on the edge of what we're doing
```
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

