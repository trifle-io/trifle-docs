---
title: 'Getting started with `Trifle::Docs`'
date: '2022-06-20 15:25:55 +0200'
tags: ['some', 'tag']
nav_order: -1
---

# Getting started with `Trifle::Docs`

Welcome to our first post

![Screen](screen.png)

## Time to get serious

Yeah, lets do that

## Or maybe no

Ok.

```ruby
require 'rest-client'

module Cron
  class SubmitSomethingWorker
    include Sidekiq::Worker

    def perform(some_id)
      Rails.logger.info "Start processing"
      something = Something.find(some_id)
      Rails.logger.info "Found record in DB"
      body = { code: something.code, count: 100 }
      Rails.logger.info "Sending payload: #{body}"

      RestClient.post('http://example.com/something', body)
      Rails.logger.info "Done?"
    end
  end
end
```
