require File.dirname(__FILE__) + '/../test_helper'

class SubdomainTest < ActiveSupport::TestCase

  context "with a saved subdomain" do
    setup do
      @subdomain = Factory(:subdomain)
    end
    subject { @subdomain }

    should_have_many :rubygems
    should_have_and_belong_to_many :users

    should_allow_values_for     :name, "foo",  "bar"
    should_not_allow_values_for :name, "foo0", "bar.", "Baz", " foo"
  end

end
