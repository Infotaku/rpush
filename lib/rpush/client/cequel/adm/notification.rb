module Rpush
  module Client
    module Cequel
      module Adm
        class Notification < Rpush::Client::Cequel::Notification
          include Rpush::Client::ActiveModel::Adm::Notification
        end
      end
    end
  end
end
