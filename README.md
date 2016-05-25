# sidekiq-qlimit
Per Queue Limit for Sidekiq

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

