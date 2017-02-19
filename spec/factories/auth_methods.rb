FactoryGirl.define do
  factory :auth_method do
    to_create { |resource| resource.save }

    user
    provider_name 'test'
    sequence(:provider_id) { |n| n }
  end
end
