# == Schema Information
#
# Table name: followers
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  reviewed   :boolean
#

require 'test_helper'

class FollowerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
