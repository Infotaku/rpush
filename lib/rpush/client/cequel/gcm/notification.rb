module Rpush
  module Client
    module Cequel
      module Gcm
        class Notification < Rpush::Client::Cequel::Notification
          include Rpush::Client::ActiveModel::Gcm::Notification
        end
      end
    end
  end
end
