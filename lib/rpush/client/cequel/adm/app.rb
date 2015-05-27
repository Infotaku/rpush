module Rpush
  module Client
    module Cequel
      module Adm
        class App < Rpush::Client::Cequel::App
          include Rpush::Client::ActiveModel::Adm::App

          # TODO: Copy structure from mongoid
        end
      end
    end
  end
end
