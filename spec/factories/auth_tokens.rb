FactoryGirl.define do
  factory :auth_token do
    to_create { |resource| resource.save }

    user
    auth_method
    last_used_at { Time.now }
  end
end
