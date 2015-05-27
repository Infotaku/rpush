module Rpush
  module Client
    module Cequel
      module Gcm
        class App < Rpush::Client::Cequel::App
          include Rpush::Client::ActiveModel::Gcm::App
        end
      end
    end
  end
end
