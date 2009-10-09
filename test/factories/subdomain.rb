Factory.sequence(:subdomain_name) { |n| "subdomain#{(97+n).chr}" }

Factory.define :subdomain do |subdomain|
  subdomain.name { Factory.next(:subdomain_name) }
end
