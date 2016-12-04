class Server < ApplicationRecord
  belongs_to :user, optional: true
end
