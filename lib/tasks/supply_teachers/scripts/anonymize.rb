#!/usr/bin/env ruby
require 'bundler/setup'
require 'faker'
require 'json'
require 'jsonpath'
require 'securerandom'

Faker::Config.locale = 'en-GB'

json = ARGF.read
hash =
  JsonPath
  .for(json)
  .gsub('..supplier_name') { Faker::Company.unique.name }
  .gsub('..supplier_id') { SecureRandom.uuid }
  .gsub('..telephone') { Faker::PhoneNumber.unique.phone_number }
  .gsub('..contacts.*.name') { Faker::Name.unique.name }
  .gsub('..contacts.*.email') { Faker::Internet.unique.email }
  .gsub('..master_vendor_contact.telephone') { Faker::PhoneNumber.unique.phone_number }
  .gsub('..master_vendor_contact.name') { Faker::Name.unique.name }
  .gsub('..master_vendor_contact.email') { Faker::Internet.unique.email }
  .gsub('..neutral_vendor_contact.telephone') { Faker::PhoneNumber.unique.phone_number }
  .gsub('..neutral_vendor_contact.name') { Faker::Name.unique.name }
  .gsub('..neutral_vendor_contact.email') { Faker::Internet.unique.email }
  .gsub('..branch_name'){ Faker::Company.unique.name }
  .to_hash
# rubocop:disable Rails/Output
puts JSON.pretty_generate(hash)
# rubocop:enable Rails/Output