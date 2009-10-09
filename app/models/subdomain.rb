class Subdomain < ActiveRecord::Base

  has_many :rubygems
  has_and_belongs_to_many :users

  validates_format_of :name, :with => /\A[a-z]+\Z/

  def belongs_to?(user)
    users.find_by_id(user.id)
  end

end
