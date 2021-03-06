# == Schema Information
#
# Table name: followers
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  reviewed   :boolean
#  nickname   :string
#  first_name :string
#  last_name  :string
#
FactoryBot.define do
  factory :follower do
    name { "Noelia Hurtado" }
    first_name { "Noelia" }
    last_name { "Hurtado" }
    nickname { "" }
    reviewed { true }
  end

  factory :random_follower do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    name { "#{Faker::Name.first_name} #{Faker::Name.last_name}" }
  end
end
