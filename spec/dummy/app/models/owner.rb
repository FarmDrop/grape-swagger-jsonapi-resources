class Owner < ApplicationRecord
  has_many :cats
  has_many :dogs
  has_one :pig
end