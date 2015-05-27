module Rpush
  module Client
    module Cequel
      module Wpns
        class Notification < Rpush::Client::Cequel::Notification
          include Rpush::Client::ActiveModel::Wpns::Notification
        end
      end
    end
  end
end
