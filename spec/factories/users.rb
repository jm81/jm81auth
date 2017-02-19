FactoryGirl.define do
  factory :user do
    to_create { |resource| resource.save }
  end
end
