class AddSubdomainsToRubygems < ActiveRecord::Migration
  def self.up
    add_column :rubygems, :subdomain, :string
  end

  def self.down
    remove_column :rubygems, :subdomain
  end
end
