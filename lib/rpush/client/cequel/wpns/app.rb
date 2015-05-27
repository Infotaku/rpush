module Rpush
  module Client
    module Cequel
      module Wpns
        class App < Rpush::Client::Cequel::App
          include Rpush::Client::ActiveModel::Wpns::App
        end
      end
    end
  end
end
