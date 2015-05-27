module Rpush
  module Client
    module Cequel
      module Apns
        class App < Rpush::Client::Cequel::App
          include Rpush::Client::ActiveModel::Apns::App
        end
      end
    end
  end
end
